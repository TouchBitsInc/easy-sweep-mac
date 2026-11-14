/* Easy Sweep — the language a visitor first lands in.
   On the English home page only, a visitor who has never picked a language is
   sent to the page in the first language their browser asks for that the site
   has. Picking one from the footer is remembered and always wins, English
   included, so nobody is moved off a page they chose. */
(function () {
  var KEY = 'easysweep.lang';
  var pages = {
    de: '/de/', es: '/es/', fr: '/fr/', it: '/it/', nl: '/nl/', pl: '/pl/',
    'pt-BR': '/pt-br/', tr: '/tr/', ru: '/ru/', uk: '/uk/', ja: '/ja/', ko: '/ko/',
    'zh-Hans': '/zh-hans/', 'zh-Hant': '/zh-hant/', 'zh-HK': '/zh-hk/'
  };

  function remember(code) {
    try { localStorage.setItem(KEY, code); } catch (e) {}
  }
  // Loaded in the head, so the move happens before anything is drawn; the
  // footer's links are wired once they exist.
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.langs a[data-lang]').forEach(function (a) {
      a.addEventListener('click', function () { remember(a.getAttribute('data-lang')); });
    });
  });

  if (location.pathname !== '/' && location.pathname !== '/index.html') return;
  var chosen = null;
  try { chosen = localStorage.getItem(KEY); } catch (e) {}
  if (chosen) return;

  // A browser's tag for the page that suits it: zh-TW is Traditional, zh-HK and
  // zh-MO Hong Kong's, any other Chinese Simplified; any Portuguese gets Brazil's.
  function page(tag) {
    var t = tag.toLowerCase(), base = t.split('-')[0];
    if (base === 'en') return 'en';
    if (base === 'zh') {
      if (/-(hk|mo)\b/.test(t)) return 'zh-HK';
      if (/-(tw|hant)\b/.test(t)) return 'zh-Hant';
      return 'zh-Hans';
    }
    if (base === 'pt') return 'pt-BR';
    return pages[base] ? base : null;
  }
  var wanted = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || 'en'];
  for (var i = 0; i < wanted.length; i++) {
    var code = page(wanted[i]);
    if (code === 'en') return;
    if (code) { location.replace(pages[code] + location.hash); return; }
  }
})();
