/* Progressive enhancement only: every page is complete without this file.
   The inline snippet in <head> adds `js` to <html>; CSS hides [data-reveal]
   only under that class, so with scripts off everything is simply visible. */
(function () {
  var root = document.documentElement;
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---- header shadow once the page scrolls ---- */
  var header = document.querySelector('.site-header');
  if (header) {
    var onScroll = function () { header.classList.toggle('is-scrolled', window.scrollY > 8); };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ---- stagger index for children of [data-stagger] ---- */
  document.querySelectorAll('[data-stagger]').forEach(function (group) {
    Array.prototype.forEach.call(group.children, function (child, i) {
      child.setAttribute('data-reveal', '');
      child.style.setProperty('--i', i);
    });
  });

  var revealEls = document.querySelectorAll('[data-reveal]');
  var counters = document.querySelectorAll('[data-count]');

  function setFinal(el) { el.textContent = el.getAttribute('data-count') + (el.getAttribute('data-suffix') || ''); }

  function countUp(el) {
    var target = parseInt(el.getAttribute('data-count'), 10) || 0;
    var suffix = el.getAttribute('data-suffix') || '';
    var start = null, dur = 900;
    function step(ts) {
      if (start === null) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
    // Background tabs throttle animation frames; never leave a number half-counted.
    setTimeout(function () { setFinal(el); }, dur + 150);
  }

  if (reduce || !('IntersectionObserver' in window)) {
    revealEls.forEach(function (el) { el.classList.add('is-visible'); });
    counters.forEach(setFinal);
    return;
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      var el = entry.target;
      el.classList.add('is-visible');
      if (el.hasAttribute('data-count')) countUp(el);
      io.unobserve(el);
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });

  revealEls.forEach(function (el) { io.observe(el); });
  // Counters keep their final value in the markup until the count actually
  // starts, so a page whose observer never fires still shows real numbers.
  counters.forEach(function (el) { io.observe(el); });

  root.classList.add('js-ready');
})();
