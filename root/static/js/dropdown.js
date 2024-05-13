window.addEventListener('DOMContentLoaded', () => {
    for (const el of document.querySelectorAll('.dropdown select')) {
        el.addEventListener('change', e => {
            document.location.href = e.target.value;
        });
    }
});
