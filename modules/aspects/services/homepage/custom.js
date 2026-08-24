(function () {
  function tagPixelGroups() {
    document.querySelectorAll('.service-group-name').forEach(function (h) {
      var name = (h.textContent || '').trim().toLowerCase();
      var group = h.closest('.services-group');
      if (group && name) {
        group.setAttribute('data-pixel-group', name);
      }
    });
  }

  function addFriendlyDecor() {
    if (document.getElementById('parpa-friendly-decor')) return;

    var layer = document.createElement('div');
    layer.id = 'parpa-friendly-decor';
    layer.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:0;overflow:visible;';

    var sprites = [
      ['parpa-scatter parpa-scatter-xl parpa-decor-moon', { top: '1.5rem', right: '1.5rem' }],
      ['parpa-scatter parpa-scatter-lg parpa-decor-cloud', { top: '5rem', left: '1rem' }],
      ['parpa-scatter parpa-scatter-xl parpa-decor-potted-plant', { bottom: '1rem', left: '1rem' }],
      ['parpa-scatter parpa-scatter-xl parpa-decor-watering-can', { bottom: '1rem', right: '1rem' }],
      ['parpa-scatter parpa-scatter-md parpa-decor-butterfly', { top: '11rem', right: '8rem' }],
      ['parpa-scatter parpa-scatter-md parpa-decor-bee', { top: '14rem', left: '8rem' }]
    ];

    sprites.forEach(function (s) {
      var el = document.createElement('div');
      el.className = s[0];
      el.style.top = s[1].top || '';
      el.style.bottom = s[1].bottom || '';
      el.style.left = s[1].left || '';
      el.style.right = s[1].right || '';
      el.style.opacity = '0.65';
      layer.appendChild(el);
    });

    document.body.appendChild(layer);
  }

  function init() {
    tagPixelGroups();
    addFriendlyDecor();
    if (typeof MutationObserver !== 'undefined') {
      new MutationObserver(function (mutations) {
        var changed = false;
        mutations.forEach(function (m) {
          m.addedNodes.forEach(function (n) {
            if (n.nodeType !== 1) return;
            if (
              (n.classList && n.classList.contains('service-group-name')) ||
              n.querySelector('.service-group-name')
            ) {
              changed = true;
            }
          });
        });
        if (changed) {
          tagPixelGroups();
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
