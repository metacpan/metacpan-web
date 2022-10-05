window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.dropdown select').forEach( el => {
        el.addEventListener('change', e => {
            document.location.href = e.target.value;
        });
    });
});
