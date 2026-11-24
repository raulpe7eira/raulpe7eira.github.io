// Unknown address (404.html): send visitors to the home page in their
// language. The homes other than "/" come from <html data-homes>.
(function () {
  var homes = JSON.parse(document.documentElement.dataset.homes || "[]");
  var path = location.pathname;
  var home = homes.find(function (prefix) {
    return path === prefix.slice(0, -1) || path.indexOf(prefix) === 0;
  });
  location.replace(home || "/");
})();
