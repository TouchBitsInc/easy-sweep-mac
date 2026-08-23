/* Easy Sweep — easysweep.app */

// Nav gains a hairline border once the page has moved.
(function () {
  var nav = document.getElementById('nav');
  if (!nav) return;
  var tick = function () {
    nav.classList.toggle('is-stuck', window.scrollY > 8);
  };
  tick();
  window.addEventListener('scroll', tick, { passive: true });
})();

// Reveal on scroll. Elements are visible by default if this never runs.
(function () {
  var targets = document.querySelectorAll('.reveal');
  if (!targets.length) return;

  if (!('IntersectionObserver' in window) ||
      window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    targets.forEach(function (el) { el.classList.add('is-in'); });
    return;
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-in');
      io.unobserve(entry.target);
    });
  }, { rootMargin: '0px 0px -12% 0px', threshold: 0.08 });

  targets.forEach(function (el) { io.observe(el); });
})();
