document.addEventListener('DOMContentLoaded', () => {
  if (
    // Development
    window.location.href === 'http://0.0.0.0:5001/' ||
    window.location.href === 'http://localhost:5001/' ||

    // Staging
    window.location.href === 'https://web.stage.hc.metacpan.org/' ||

    // Production
    window.location.href === 'https://metacpan.org/' ||
    window.location.href === 'https://grep.metacpan.org/'
  ) {
    document.body.classList.add('page-home');
  }
});
