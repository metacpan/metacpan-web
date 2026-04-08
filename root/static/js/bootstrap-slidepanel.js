'use strict';

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const animDuration = prefersReducedMotion ? 0 : 200;

for (const toggle of document.querySelectorAll('[data-bs-toggle="slidepanel"]')) {
    const panel = document.querySelector(toggle.dataset.bsTarget);
    if (!panel) {
        continue;
    }

    const showAnim = new Animation(new KeyframeEffect(
        panel, {
            transform: ['translateX(-100%)', 'translateX(0)'],
        },
        animDuration,
    ));

    const hideAnim = new Animation(new KeyframeEffect(
        panel, {
            transform: ['translateX(0)', 'translateX(-100%)'],
        },
        animDuration,
    ));
    hideAnim.addEventListener('finish', () => {
        panel.style.removeProperty('visibility');
    });

    toggle.addEventListener('click', function (e) {
        e.preventDefault();

        toggle.classList.toggle('slidepanel-visible');
        panel.style.visibility = 'visible';
        const isOpen = panel.classList.toggle('slidepanel-visible');
        toggle.setAttribute('aria-expanded', String(isOpen));
        if (isOpen) {
            showAnim.play();
        }
        else {
            hideAnim.play();
        }
    });
}
