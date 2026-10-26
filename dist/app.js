function myFunction() {
    var x = document.getElementById("mobile");
    if (x.className === "mobile") {
      x.className += " responsive";
    } else {
      x.className = "mobile";
    }
  }

// Bound here instead of an onclick attribute: the CSP allows no inline script,
// and an event handler attribute counts as one.
document.querySelector(".navHeader .icon").addEventListener("click", function (event) {
  event.preventDefault();
  myFunction();
});

AOS.init();
