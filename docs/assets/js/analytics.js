// Google Analytics (GA4), only with consent (LGPD). Nothing loads before the
// visitor chooses in the banner (#consent, in the layout) or if they decline.
// The choice lives in localStorage; the privacy page has a button
// ([data-consent-reset]) that clears it, deletes the _ga cookies and shows the
// banner again. GA4 loads only on raulpe7eira.tech; add ?ga=debug to the URL to
// load it elsewhere (e.g. localhost) in debug mode, for the rest of the tab.
(function () {
  var KEY = "analytics-consent";
  var ID = "G-4QXLD8YPLP";
  var debug = debugMode();
  var enabled = location.hostname === "raulpe7eira.tech" || debug;

  // ?ga=debug is remembered for the tab (sessionStorage), so it survives
  // following links (e.g. to the privacy page) and reloads
  function debugMode() {
    try {
      if (/[?&]ga=debug(&|$)/.test(location.search)) sessionStorage.setItem("ga-debug", "1");
      return sessionStorage.getItem("ga-debug") === "1";
    } catch (e) {
      return /[?&]ga=debug(&|$)/.test(location.search);
    }
  }

  function readChoice() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function saveChoice(choice) {
    try { localStorage.setItem(KEY, choice); } catch (e) {}
  }

  function clearChoice() {
    try { localStorage.removeItem(KEY); } catch (e) {}
  }

  function loadAnalytics() {
    if (!enabled || window.gtag) return;
    var script = document.createElement("script");
    script.async = true;
    script.src = "https://www.googletagmanager.com/gtag/js?id=" + ID;
    document.head.appendChild(script);
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { dataLayer.push(arguments); };
    gtag("js", new Date());
    gtag("config", ID, debug ? { debug_mode: true } : {});
  }

  // GA4 sets _ga and _ga_<id> on the site's domain (with a leading dot)
  function deleteAnalyticsCookies() {
    var domains = ["", "; domain=" + location.hostname, "; domain=." + location.hostname];
    document.cookie.split(";").forEach(function (cookie) {
      var name = cookie.split("=")[0].trim();
      if (name !== "_ga" && name.indexOf("_ga_") !== 0) return;
      domains.forEach(function (domain) {
        document.cookie = name + "=; max-age=0; path=/" + domain;
      });
    });
  }

  function whenReady(callback) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", callback);
    else callback();
  }

  if (readChoice() === "granted") loadAnalytics();

  whenReady(function () {
    var banner = document.getElementById("consent");
    if (!banner) return;
    if (!readChoice()) banner.hidden = false;

    banner.addEventListener("click", function (event) {
      var choice = event.target.getAttribute("data-consent");
      if (!choice) return;
      saveChoice(choice);
      banner.hidden = true;
      if (choice === "granted") loadAnalytics();
    });

    document.querySelectorAll("[data-consent-reset]").forEach(function (button) {
      button.addEventListener("click", function () {
        var previous = readChoice();
        clearChoice();
        deleteAnalyticsCookies();
        // a loaded GA4 can't be unloaded: reload so it is gone
        if (previous === "granted") location.reload();
        else banner.hidden = false;
      });
    });
  });
})();
