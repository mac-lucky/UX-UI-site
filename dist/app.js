function myFunction() {
    var x = document.getElementById("mobile");
    if (x.className === "mobile") {
      x.className += " responsive";
    } else {
      x.className = "mobile";
    }
  }

// First: aos.css hides every [data-aos] block until AOS animates it, so nothing
// that can throw may run before this.
AOS.init();

// Bound here instead of an onclick attribute: the CSP allows no inline script,
// and an event handler attribute counts as one.
document.querySelector(".navHeader .icon")?.addEventListener("click", function (event) {
  event.preventDefault();
  myFunction();
});
