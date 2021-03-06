function myFunction() {
    var x = document.getElementById("mobile");
    if (x.className === "mobile") {
      x.className += " responsive";
    } else {
      x.className = "mobile";
    }
  }