// Recommendations on the resume: clicking a card moves it to the top, across
// the whole width (the others line up below it, see resume.css; on phones it
// opens in place), and types
// the rest of the text around the highlight (which stays in bold where it
// is), with a caret; clicking again erases it back to the highlight. The speed follows the
// length, so long and short ones take about as long. Clicking again mid-way
// turns around from where it is. Without JS, or with reduced motion, the
// <details> just opens and closes.
(function () {
  var reduce = matchMedia("(prefers-reduced-motion: reduce)");

  // on wide screens the cards slide to their new places as a view
  // transition, where the browser has them (see resume.css); `then` runs
  // once they are there. On phones the card opens in place: nothing moves.
  var phone = matchMedia("(max-width: 700px)");
  function move(update, then) {
    if (!document.startViewTransition || phone.matches) {
      update();
      return then();
    }
    document.startViewTransition(update).finished.then(then, then);
  }

  document.querySelectorAll(".rc").forEach(function (card, index) {
    card.style.viewTransitionName = "rc-" + index;
    card.style.viewTransitionClass = "rcard";
  });

  document.querySelectorAll(".rc .rq").forEach(function (box) {
    var details = box.querySelector("details");
    var summary = details.querySelector("summary");
    var text = details.querySelector("blockquote");
    var paragraphs = Array.prototype.slice.call(text.querySelectorAll("p"));

    // the text outside the highlight, in reading order
    var pieces = [];
    var walker = document.createTreeWalker(text, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        return node.parentNode.closest(".hit") ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
      }
    });
    while (walker.nextNode()) pieces.push({ node: walker.currentNode, full: walker.currentNode.data });
    var total = pieces.reduce(function (sum, piece) { return sum + piece.full.length; }, 0);

    var caret = document.createElement("span");
    caret.className = "caret";
    caret.setAttribute("aria-hidden", "true");

    var shown = total;
    var frame = null;

    function render(count) {
      var left = count;
      var at = null;
      pieces.forEach(function (piece) {
        var visible = Math.max(0, Math.min(piece.full.length, left));
        piece.node.data = piece.full.slice(0, visible);
        if (!at && visible < piece.full.length) at = piece.node;
        left -= piece.full.length;
      });
      paragraphs.forEach(function (p) {
        p.hidden = !p.querySelector(".hit") && !p.textContent.trim();
      });
      if (at) at.after(caret);
      else caret.remove();
    }

    function run(to, duration, done) {
      cancelAnimationFrame(frame);
      var from = shown;
      var start = performance.now();
      (function step(now) {
        var progress = Math.min(1, (now - start) / duration);
        shown = Math.round(from + (to - from) * progress);
        render(shown);
        if (progress < 1) frame = requestAnimationFrame(step);
        else {
          caret.remove();
          if (done) done();
        }
      })(start);
    }

    // about 1 ms per character, between 0.7 and 2.2 s to type it all
    var typing = Math.min(2200, Math.max(700, total));

    // the whole card toggles it, except the link to the recommender and a
    // click that ends a text selection
    box.closest(".rc").addEventListener("click", function (event) {
      if (event.target.closest("a, summary")) return;
      if (String(getSelection())) return;
      summary.click();
    });

    summary.addEventListener("click", function (event) {
      if (reduce.matches || !total) return;
      event.preventDefault();
      var opening = !details.open || box.classList.contains("erasing");
      if (opening) {
        box.classList.remove("erasing");
        var type = function () { run(total, typing * (total - shown) / total); };
        if (details.open) return type();
        move(function () {
          shown = 0;
          render(0);
          details.open = true;
        }, function () {
          // it moved to the top of the recommendations: bring it into view
          var card = box.closest(".rc");
          if (!phone.matches && card.getBoundingClientRect().top < 0) card.scrollIntoView({ behavior: "smooth", block: "start" });
          type();
        });
      } else {
        box.classList.add("erasing");
        run(0, typing * 0.45 * shown / total, function () {
          box.classList.remove("erasing");
          move(function () {
            details.open = false;
            shown = total;
            render(total);
          }, function () {});
        });
      }
    });
  });
})();
