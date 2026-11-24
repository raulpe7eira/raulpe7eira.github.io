// Career bar under "Experience" on the resume: a click scrolls to the
// company (smoothly, unless reduced motion), and the company on screen lights
// up in the bar (.on). Without JS the bars are plain links to #xp-… anchors.
(function () {
  var nav = document.querySelector(".tlm");
  if (!nav) return;
  var reduce = matchMedia("(prefers-reduced-motion: reduce)");
  var links = Array.prototype.slice.call(nav.querySelectorAll("a"));
  var target = function (link) { return document.getElementById(link.getAttribute("href").slice(1)); };

  function mark(id) {
    links.forEach(function (link) {
      link.classList.toggle("on", link.getAttribute("href") === "#" + id);
    });
  }

  links.forEach(function (link) {
    link.addEventListener("click", function (event) {
      var item = target(link);
      if (!item) return;
      event.preventDefault();
      item.scrollIntoView({ behavior: reduce.matches ? "auto" : "smooth", block: "start" });
      history.replaceState(null, "", link.getAttribute("href"));
      mark(item.id);
    });
  });

  // stuck to the top, the bar gets an opaque background (the text scrolls under it)
  var ticking = false;
  function stuck() {
    ticking = false;
    nav.classList.toggle("stuck", nav.getBoundingClientRect().top <= 1);
  }
  addEventListener("scroll", function () {
    if (!ticking) { ticking = true; requestAnimationFrame(stuck); }
  }, { passive: true });
  stuck();

  // the company crossing a line just below the bar is the one being read
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) mark(entry.target.id);
    });
  }, { rootMargin: "-90px 0px -75% 0px" });
  links.map(target).forEach(function (item) { if (item) observer.observe(item); });
})();
