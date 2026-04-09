function getPreferredTheme() {
    const stored = localStorage.getItem('theme');
    if (stored) return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    updateToggleIcon(theme);
}

function updateToggleIcon(theme) {
    const btn = document.querySelector('.theme-toggle');
    if (!btn) return;
    const icon = btn.querySelector('i');
    if (!icon) return;
    icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    btn.setAttribute('aria-label',
        theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
}

// Listen for OS preference changes (only when user hasn't explicitly chosen)
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme-source')) {
        const theme = e.matches ? 'dark' : 'light';
        setTheme(theme);
    }
});

// Set correct icon/label immediately (module scripts run after parsing)
updateToggleIcon(getPreferredTheme());

// Toggle button click
const btn = document.querySelector('.theme-toggle');
if (btn) {
    btn.addEventListener('click', () => {
        const current = document.documentElement.getAttribute('data-bs-theme');
        const next = current === 'dark' ? 'light' : 'dark';
        localStorage.setItem('theme', next);
        localStorage.setItem('theme-source', 'user');
        setTheme(next);
    });
}
