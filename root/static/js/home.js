document.addEventListener('DOMContentLoaded', () => {
  if (
    window.location.href === 'http://0.0.0.0:5001/' ||
    window.location.href === 'https://metacpan.org/' ||
    window.location.href === 'https://grep.metacpan.org/'
  ) {
    document.body.classList.add('page-home');
  }
});
