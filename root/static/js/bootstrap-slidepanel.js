(() => {
    "use strict";

    for (const toggle of document.querySelectorAll('[data-toggle="slidepanel"]')) {
        const panel = document.querySelector(toggle.dataset.target);
        if (!panel) {
            continue;
        }

        const showAnim = new Animation( new KeyframeEffect(
            panel,
            { transform: [ 'translateX(-100%)', 'translateX(0)' ] },
            200
        ));

        const hideAnim = new Animation(new KeyframeEffect(
            panel,
            { transform: [ 'translateX(0)', 'translateX(-100%)' ] },
            200
        ));
        hideAnim.addEventListener('finish', () => {
            panel.style.removeProperty('visibility');
        });

        toggle.addEventListener('click', function (e) {
            e.preventDefault();

            toggle.classList.toggle('slidepanel-visible');
            panel.style.visibility = 'visible';
            if (panel.classList.toggle('slidepanel-visible')) {
                showAnim.play();
            }
            else {
                hideAnim.play();
            }
        });
    }
})();
