#!/bin/bash
# assign the first argument passed to the script to a variable
version=$1
sed -i "s/ux-ui-site.*/ux-ui-site:$version/g" .github/manifests/portfolio-app.yml