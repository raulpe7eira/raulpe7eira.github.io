// Recommendations on the resume: clicking a card moves it to the top, across
// the whole width (the others line up two by two below it, see resume.css; on phones it
// opens in place), and types
// the rest of the text around the highlight (which stays in bold where it
// is), with a caret; clicking again erases it back to the highlight. The speed follows the
// length, so long and short ones take about as long. Clicking again mid-way
// turns around from where it is. Only one is open at a time: opening another
// erases the open one first, as if it had been clicked, then moves both in
// one go (the <details> share a name, so without JS, or with reduced motion,
// opening one just closes the others).
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

  var cards = [];  // the recommendations that open
  var next = null; // the one to open once the open one is erased

  document.querySelectorAll(".rc .rq").forEach(function (box) {
    var self = {};
    cards.push(self);
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
        var progress = duration > 0 ? Math.min(1, (now - start) / duration) : 1;
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

    function type() { run(total, typing * (total - shown) / total); }

    // inside a move: open with nothing typed yet, or close with the full text
    // back (ready for the next time)
    self.reveal = function () {
      shown = 0;
      render(0);
      details.open = true;
    };
    self.open = function () { return details.open; };
    self.hide = function () {
      details.open = false;
      shown = total;
      render(total);
    };

    // once it has moved to the top of the recommendations: bring it into
    // view and type
    self.typed = function () {
      var card = box.closest(".rc");
      if (!phone.matches && card.getBoundingClientRect().top < 0) card.scrollIntoView({ behavior: "smooth", block: "start" });
      type();
    };

    // erase back to the highlight and close; if another one is waiting, it
    // opens in the same move
    self.erase = function () {
      box.classList.add("erasing");
      run(0, typing * 0.45 * shown / total, function () {
        box.classList.remove("erasing");
        var then = next;
        next = null;
        move(function () {
          self.hide();
          if (then) then.reveal();
        }, then ? then.typed : function () {});
      });
    };

    summary.addEventListener("click", function (event) {
      if (reduce.matches || !total) return;
      event.preventDefault();
      if (!details.open) {
        var open = cards.filter(function (card) { return card !== self && card.open(); })[0];
        if (!open) return move(self.reveal, self.typed);
        next = self;
        return open.erase();
      }
      if (box.classList.contains("erasing")) {
        // turn around (and forget the one that was waiting for it)
        next = null;
        box.classList.remove("erasing");
        return type();
      }
      self.erase();
    });
  });
})();
