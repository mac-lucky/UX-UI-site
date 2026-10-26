#!/usr/bin/env bash
# Asserts what nginx actually SERVES, against a running container.
#
# `nginx -t` in the Dockerfile only proves the config parses. It cannot catch a
# wrong `location` winning, or a location that sets its own add_header and so
# drops the security headers. Every assertion below is a rule that is otherwise
# only stated in a comment in nginx/.
#
# Usage: scripts/test-nginx.sh [base-url]   (default http://localhost:8080)
#
#   docker build -t ux-ui-site . && docker run -d --rm -p 8080:8080 ux-ui-site
#   scripts/test-nginx.sh
set -uo pipefail

BASE="${1:-http://localhost:8080}"
fail=0

PAGES=(/ /projects/codersboard /projects/musicapp /projects/warsztaty)

# Response head of one request, CRs stripped. An optional second argument is
# sent as a request header.
fetch() {
	local args=(-sS -D - -o /dev/null)
	[ -n "${2:-}" ] && args+=(-H "$2")
	curl "${args[@]}" "$BASE$1" 2>/dev/null | tr -d '\r'
}

# One request, then assert on the status line and on headers. Header patterns are
# matched case-insensitively against the full response head.
check() {
	desc=$1 path=$2 want_status=$3 want_header=${4:-} reject_header=${5:-} req_header=${6:-}
	head=$(fetch "$path" "$req_header")
	status=$(printf '%s' "$head" | head -1 | awk '{print $2}')

	if [ "$status" != "$want_status" ]; then
		printf 'FAIL  %-50s status %s, want %s\n' "$desc" "${status:-none}" "$want_status"
		fail=1
		return
	fi
	if [ -n "$want_header" ] && ! printf '%s' "$head" | grep -qiE "$want_header"; then
		printf 'FAIL  %-50s missing header /%s/\n' "$desc" "$want_header"
		fail=1
		return
	fi
	if [ -n "$reject_header" ] && printf '%s' "$head" | grep -qiE "$reject_header"; then
		printf 'FAIL  %-50s unexpected header /%s/\n' "$desc" "$reject_header"
		fail=1
		return
	fi
	printf 'ok    %s\n' "$desc"
}

SECURITY_HEADERS=(
	'^content-security-policy: '
	'^x-content-type-options: nosniff$'
	'^x-frame-options: deny$'
	'^strict-transport-security: max-age=[1-9]'
	'^referrer-policy: strict-origin-when-cross-origin$'
	'^permissions-policy: '
	'^cross-origin-opener-policy: same-origin$'
)

# The whole security set on one response. A location that sets Cache-Control
# and forgets the include ships none of them.
check_security() {
	path=$1 want_status=$2
	head=$(fetch "$path")
	status=$(printf '%s' "$head" | head -1 | awk '{print $2}')
	if [ "$status" != "$want_status" ]; then
		printf 'FAIL  %-50s status %s, want %s\n' "security headers on $path" "${status:-none}" "$want_status"
		fail=1
		return
	fi
	missing=""
	for h in "${SECURITY_HEADERS[@]}"; do
		printf '%s' "$head" | grep -qiE "$h" || missing="$missing /$h/"
	done
	if [ -n "$missing" ]; then
		printf 'FAIL  %-50s missing%s\n' "security headers on $path" "$missing"
		fail=1
		return
	fi
	printf 'ok    %s\n' "security headers on $path ($want_status)"
}

# Pages and their own assets.
for p in "${PAGES[@]}"; do
	check "page $p" "$p" 200 '^content-type: text/html'
done
check "stylesheet"                         "/style.css"          200 '^content-type: text/css'
check "home page script"                   "/app.js"             200 '^content-type: (application|text)/javascript'
check "warsztaty script"                   "/projects/warsztaty.js" 200 '^content-type: (application|text)/javascript'
check "resume pdf"                         "/projects/CV_Wiktoria_Sawicka_ENG.pdf" 200 '^content-type: application/pdf'

# Security headers on every kind of response, the media location, redirects and
# errors included.
for p in "${PAGES[@]}" /style.css /app.js /images/LOGO.png /videos/Pomocnik_1.webm /health; do
	check_security "$p" 200
done
check_security "/projects/musicapp.html" 301
check_security "/no-such-page"           404
check_security "/images/no-such.png"     404

check "Server header carries no version"   "/"                   200 '' '^server: .*[0-9]'

# Neither directive may fall back to 'unsafe-inline': the pages carry no inline
# script, event handler attribute or style attribute, and must not grow one.
check "script-src has no unsafe-inline"    "/"                   200 'content-security-policy:.*script-src ' \
                                                                     "content-security-policy:.*script-src[^;]*unsafe-inline"
check "style-src has no unsafe-inline"     "/"                   200 'content-security-policy:.*style-src ' \
                                                                     "content-security-policy:.*style-src[^;]*unsafe-inline"

# Compression.
check "html is gzipped when asked"         "/"                   200 '^content-encoding: gzip' '' 'Accept-Encoding: gzip'
check "css is gzipped when asked"          "/style.css"          200 '^content-encoding: gzip' '' 'Accept-Encoding: gzip'
check "gzip varies on Accept-Encoding"     "/"                   200 '^vary: accept-encoding' '' 'Accept-Encoding: gzip'
check "no gzip unless asked"               "/"                   200 '' '^content-encoding:'

# Caching. Nothing here is content-hashed, so nothing may be `immutable`.
check "page is short-lived at the edge"    "/"                   200 'cache-control:.*s-maxage=60'
check "css is short-lived"                 "/style.css"          200 'cache-control:.*s-maxage=60'
check "image is cached a week"             "/images/LOGO.png"    200 'cache-control:.*max-age=604800' 'cache-control:.*immutable'
check "video is cached a week"             "/videos/Pomocnik_1.webm" 200 'cache-control:.*max-age=604800' 'cache-control:.*immutable'
check "missing image is not cached a week" "/images/no-such.png" 404 '' 'cache-control:.*max-age=604800'
check "redirect carries the short policy"  "/projects/musicapp.html" 301 'cache-control:.*s-maxage=60'

# Canonical URL shape.
check "/index.html redirects"              "/index.html"         301 '^location: /$'
check "/index redirects"                   "/index"              301 '^location: /$'
check ".html extension collapses"          "/projects/musicapp.html" 301 '^location: /projects/musicapp$'
check "query survives the redirect"        "/projects/musicapp.html?utm_source=x" 301 '^location: /projects/musicapp\?utm_source=x$'
check "trailing slash collapses"           "/projects/musicapp/" 301 '^location: /projects/musicapp$'
check "redirect is relative"               "/projects/musicapp/" 301 '' '^location: https?:'
# A capture starting with a backslash would become an off-origin Location.
check "backslash .html is not redirected"  "/%5Cevil.com.html"   404 '' '^location:'
check "backslash slash is not redirected"  "/%5Cevil.com/"       404 '' '^location:'

# Real 404s, and the base image's stock error page is gone.
check "/health answers"                    "/health"             200 '^content-type: text/plain'
check "unknown path is a real 404"         "/no-such-page"       404
check "directory without index is a 404"   "/projects"           404
check "/50x.html redirects like any page"  "/50x.html"           301 '^location: /50x$'
check "/50x is gone"                       "/50x"                404

# Every third-party stylesheet and script a page loads must be allowed by the
# CSP. Renovate bumps the cdnjs URLs in the HTML; a new library or origin there
# fails here instead of silently losing its styles in the browser.
csp=$(fetch / | grep -i '^content-security-policy:' | cut -d: -f2-)
directive() { printf '%s' "$csp" | tr ';' '\n' | sed -n "s/^ *$1 //p"; }
allowed() {
	for src in $2; do
		case $src in
		https://*/) [[ $1 == "$src"* ]] && return 0 ;;
		https://*/*) [[ $1 == "$src" ]] && return 0 ;;
		https://*) [[ $1 == "$src"/* ]] && return 0 ;;
		esac
	done
	return 1
}
script_src=$(directive script-src)
style_src=$(directive style-src)
for p in "${PAGES[@]}"; do
	body=$(curl -sS "$BASE$p" | tr '\r\n' '  ')
	bad=""
	while read -r url; do
		[ -n "$url" ] && ! allowed "$url" "$script_src" && bad="$bad $url"
	done < <(printf '%s' "$body" | grep -oiE '<script[^>]*>' | grep -oE 'src="https://[^"]*"' | cut -d'"' -f2)
	while read -r url; do
		[ -n "$url" ] && ! allowed "$url" "$style_src" && bad="$bad $url"
	done < <(printf '%s' "$body" | grep -oiE '<link[^>]*>' | grep -i 'stylesheet' | grep -oE 'href="https://[^"]*"' | cut -d'"' -f2)
	if [ -n "$bad" ]; then
		printf 'FAIL  %-50s not allowed by the CSP:%s\n' "CSP covers what $p loads" "$bad"
		fail=1
	else
		printf 'ok    %s\n' "CSP covers what $p loads"
	fi
done

echo
if [ "$fail" -ne 0 ]; then
	echo "nginx behaviour checks FAILED"
	exit 1
fi
echo "nginx behaviour checks passed"
