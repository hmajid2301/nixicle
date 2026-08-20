(function () {
  var THEMES = [
    { id: "catppuccin", label: "CAT" }
  ];

  function getStoredTheme() {
    try {
      return localStorage.getItem("parpa-theme");
    } catch (e) {
      return null;
    }
  }

  function setStoredTheme(id) {
    try {
      localStorage.setItem("parpa-theme", id);
    } catch (e) {
      // ignore
    }
  }

  function applyTheme(id) {
    if (!id || !THEMES.find(function (t) { return t.id === id; })) {
      id = "pixel";
    }
    var root = document.documentElement;
    root.classList.remove("theme-pixel", "theme-gameboy", "theme-catppuccin", "theme-crt", "theme-synthwave");
    root.classList.add("theme-" + id);
    root.setAttribute("data-parpa-theme", id);
    setStoredTheme(id);
  }

  function tagPixelGroups() {
    document.querySelectorAll('.service-group-name').forEach(function (h) {
      var name = (h.textContent || '').trim().toLowerCase();
      var group = h.closest('.services-group');
      if (group && name) {
        group.setAttribute('data-pixel-group', name);
      }
    });
  }

  function createSwitcher() {
    var footer = document.getElementById('footer');
    if (!footer) return;
    if (document.getElementById('parpa-theme-switcher')) return;

    var bar = document.createElement('div');
    bar.id = 'parpa-theme-switcher';
    bar.setAttribute('role', 'tablist');
    bar.setAttribute('aria-label', 'Theme');
    bar.style.cssText = [
      'display: flex',
      'gap: 0.45rem',
      'margin-top: 0.75rem',
      'padding: 0.5rem',
      'background: rgba(0,0,0,0.25)',
      'border: 3px solid currentColor',
      'align-items: center',
      'justify-content: center',
      'flex-wrap: wrap',
      'font-family: "Press Start 2P", monospace',
      'font-size: 0.5rem'
    ].join('; ');

    var current = document.documentElement.getAttribute('data-parpa-theme') || 'pixel';

    THEMES.forEach(function (t) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.textContent = t.label;
      btn.setAttribute('aria-pressed', t.id === current ? 'true' : 'false');
      btn.style.cssText = [
        'padding: 0.35rem 0.45rem',
        'border: 2px solid currentColor',
        'background: transparent',
        'color: inherit',
        'cursor: ' + (t.id === current ? 'default' : 'pointer'),
        'opacity: ' + (t.id === current ? '1' : '0.7')
      ].join('; ');
      btn.addEventListener('click', function () {
        applyTheme(t.id);
        createSwitcher();
      });
      bar.appendChild(btn);
    });

    footer.appendChild(bar);
  }

  function init() {
    var stored = getStoredTheme();
    applyTheme(stored);
    tagPixelGroups();
    createSwitcher();

    if (typeof MutationObserver !== 'undefined') {
      new MutationObserver(function (mutations) {
        var changed = false;
        mutations.forEach(function (m) {
          m.addedNodes.forEach(function (n) {
            if (n.nodeType !== 1) return;
            if (
              (n.classList && n.classList.contains('service-group-name')) ||
              n.querySelector('.service-group-name') ||
              n.id === 'footer'
            ) {
              changed = true;
            }
          });
        });
        if (changed) {
          tagPixelGroups();
          createSwitcher();
        }
      }).observe(document.body, { childList: true, subtree: true });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
