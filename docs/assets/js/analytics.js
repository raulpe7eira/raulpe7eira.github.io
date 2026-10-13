// Google Analytics (GA4) only on the production domain.
// Plausible ignores localhost on its own.
(function () {
  if (location.hostname !== "raulpe7eira.tech") return;
  var id = "G-4QXLD8YPLP";
  var s = document.createElement("script");
  s.async = true;
  s.src = "https://www.googletagmanager.com/gtag/js?id=" + id;
  document.head.appendChild(s);
  window.dataLayer = window.dataLayer || [];
  window.gtag = function () { dataLayer.push(arguments); };
  gtag("js", new Date());
  gtag("config", id);
})();
