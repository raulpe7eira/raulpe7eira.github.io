// Tooltips for [data-tip] on the resume: the ⓘ of a closed school and the
// "acquired" badges on the logos.
// With a mouse, the tip shows at once on hover; a click still follows the
// link around it. On touch screens (no hover), a tap shows the tip instead
// of following the link; tapping it again or elsewhere, scrolling or Esc
// hides it. One tip element for the whole page, placed over it, since the
// logos clip what is inside them.
(function () {
  var triggers = document.querySelectorAll("[data-tip]");
  if (!triggers.length) return;

  var tip = document.createElement("div");
  tip.className = "tip";
  tip.setAttribute("role", "tooltip");
  tip.hidden = true;
  document.body.appendChild(tip);

  var touch = matchMedia("(hover: none)");
  var current = null;
  var gap = 8;

  // the link around the ⓘ has a title (the school's name), which the browser
  // would show too after a moment: set aside while the tip is up
  var muted = null;

  function show(trigger) {
    unmute();
    current = trigger;
    muted = trigger.closest("[title]");
    if (muted) {
      muted.setAttribute("data-title", muted.title);
      muted.removeAttribute("title");
    }
    tip.textContent = trigger.getAttribute("data-tip");
    tip.hidden = false;

    // above the trigger (below it when there is no room), inside the window
    var target = trigger.getBoundingClientRect();
    var box = tip.getBoundingClientRect();
    var width = document.documentElement.clientWidth;
    var left = Math.min(Math.max(target.left + target.width / 2 - box.width / 2, gap), width - box.width - gap);
    var top = target.top - box.height - gap < 0 ? target.bottom + gap : target.top - box.height - gap;
    tip.style.left = left + window.scrollX + "px";
    tip.style.top = top + window.scrollY + "px";
  }

  function hide() {
    unmute();
    current = null;
    tip.hidden = true;
  }

  function unmute() {
    if (!muted) return;
    muted.title = muted.getAttribute("data-title");
    muted.removeAttribute("data-title");
    muted = null;
  }

  triggers.forEach(function (trigger) {
    trigger.addEventListener("mouseenter", function () { if (!touch.matches) show(trigger); });
    trigger.addEventListener("mouseleave", function () { if (!touch.matches) hide(); });
    trigger.addEventListener("click", function (event) {
      if (!touch.matches) return;
      event.preventDefault();
      event.stopPropagation();
      if (current === trigger) hide();
      else show(trigger);
    });
  });

  document.addEventListener("click", function () { if (current) hide(); });
  document.addEventListener("keydown", function (event) { if (event.key === "Escape") hide(); });
  window.addEventListener("scroll", function () { if (current) hide(); }, { passive: true });
  window.addEventListener("resize", function () { if (current) hide(); });
})();
