window.addEventListener('DOMContentLoaded', async () => {
    'use strict';

    function recaptcha_prepare () {
        return new Promise ((resolve, reject) => {
            const recaptcha_script = document.createElement('script');
            recaptcha_script.setAttribute('async', '');
            recaptcha_script.setAttribute('defer', '');
            recaptcha_script.setAttribute('src', 'https://www.google.com/recaptcha/api.js?render=explicit');
            recaptcha_script.addEventListener('load', () => {
                window.grecaptcha.ready(() => resolve(window.grecaptcha));
            });
            recaptcha_script.addEventListener('error', () => reject('Error loading reCAPTCHA'));
            document.head.appendChild(recaptcha_script);
        });
    }

    const recaptcha_div = document.querySelector('.g-recaptcha');
    if (!recaptcha_div) {
        return;
    }

    const recaptcha_form = recaptcha_div.closest('form');

    const grecaptcha = await recaptcha_prepare();
    grecaptcha.render(recaptcha_div, {
        callback: () => recaptcha_form.submit()
    });
});
