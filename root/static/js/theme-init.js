(function () {
    var t = localStorage.getItem('theme');
    if (!t)
        t = window.matchMedia('(prefers-color-scheme:dark)').matches
            ? 'dark' : 'light';
    document.documentElement.setAttribute('data-bs-theme', t);
})();
