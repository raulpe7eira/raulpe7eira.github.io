(function () {
  var root = document.documentElement;
  var panel = document.getElementById("theme-panel");
  var meta = document.querySelector('meta[name="theme-color"]');

  function mark(name) {
    panel.querySelectorAll("button[data-theme]").forEach(function (btn) {
      btn.classList.toggle("active", btn.dataset.theme === name);
    });
    meta.content = getComputedStyle(root).getPropertyValue("--bg").trim();
  }

  function setTheme(name) {
    if (!panel.querySelector('[data-theme="' + name + '"]')) return;
    root.dataset.theme = name;
    mark(name);
    panel.setAttribute("hidden", "");
    try { localStorage.setItem("theme", name); } catch (e) {}
  }

  document.querySelector(".theme-btn").addEventListener("click", function () {
    panel.toggleAttribute("hidden");
  });
  panel.querySelectorAll("button[data-theme]").forEach(function (btn) {
    btn.addEventListener("click", function () { setTheme(btn.dataset.theme); });
  });
  document.addEventListener("click", function (e) {
    if (!e.target.closest(".theme-btn") && !e.target.closest(".theme-panel")) panel.setAttribute("hidden", "");
  });

  mark(root.dataset.theme || "dracula");
})();
