(function () {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function (registrations) {
            if (!registrations.length) navigator.serviceWorker.register('/service_worker').then(function (worker) {
                console.log('Service Worker Registered');
            });
        });
        // because the js files are loaded in the 'head' so before the dom has been loaded.
        window.addEventListener('DOMContentLoaded', function () {
            var pwa = {
                pushButton: document.getElementById('install-pwa'),
                hideButton: function () {
                    this.pushButton.style.display = 'none';
                },
                showButton: function () {
                    this.pushButton.style.display = 'block';
                },
                deferredPrompt: undefined
            };

            window.addEventListener('beforeinstallprompt', function (e) {
                if (pwa.pushButton) {
                    e.preventDefault();
                    pwa.deferredPrompt = e;
                    pwa.showButton();
                }
            });

            if (pwa.pushButton) pwa.pushButton.addEventListener('click', function (e) {
                pwa.hideButton();    
                pwa.deferredPrompt.prompt();
                app.deferredPrompt.userChoice.then(function (choiceResult) {
                    if (choiceResult.outcome !== 'accepted') {
                        pwa.showButton();           
                    } else {
                        app.deferredPrompt = null;
                    }
                });
            });
        });
    }
})();
