for (const el of document.querySelectorAll('.dropdown select')) {
    el.addEventListener('change', () => {
        document.location.href = el.value;
    });
}
