// Plausible: site script (pa-*.js) is loaded in <head>; tracking options
// (outbound links, file downloads) are toggled in the Plausible dashboard.
// It ignores localhost by itself.
window.plausible = window.plausible || function () { (plausible.q = plausible.q || []).push(arguments); };
plausible.init = plausible.init || function (i) { plausible.o = i || {}; };
plausible.init();

// Google Analytics (GA4) only on the production domain.
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
