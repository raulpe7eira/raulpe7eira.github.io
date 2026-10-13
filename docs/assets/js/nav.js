// Resume/Currículo toggle: let the switch slide before navigating
document.querySelectorAll(".page-btn").forEach(function (a) {
  a.addEventListener("click", function (e) {
    e.preventDefault();
    a.classList.toggle("on");
    setTimeout(function () { location.href = a.href; }, 180);
  });
});

// Header intro: replay the header hover (grow, spin the photo, shrink back) when the
// site is entered, reloaded or opened in a new tab, but not when navigating inside it
(function () {
  var link = document.querySelector(".profile-link");
  if (!link || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  var nav = performance.getEntriesByType("navigation")[0];
  var type = nav ? nav.type : "navigate";
  var internal = document.referrer && new URL(document.referrer).origin === location.origin;
  if (type === "back_forward" || (type === "navigate" && internal)) return;
  window.addEventListener("load", function () {
    setTimeout(function () {
      link.classList.add("intro");
      setTimeout(function () { link.classList.remove("intro"); }, 900);
    }, 300);
  });
})();
