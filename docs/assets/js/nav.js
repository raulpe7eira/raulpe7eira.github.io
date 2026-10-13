// Resume/Currículo toggle: let the switch slide before navigating
document.querySelectorAll(".page-btn").forEach(function (a) {
  a.addEventListener("click", function (e) {
    e.preventDefault();
    a.classList.toggle("on");
    setTimeout(function () { location.href = a.href; }, 180);
  });
});
