window.dataLayer = window.dataLayer || [];

const gtag = (...args) => {
    window.dataLayer.push(args);
};

gtag('js', new Date());
gtag('config', 'G-6B2JCQSHJE', {
    cookie_flags: 'SameSite=Lax;Secure',
});

export {
    gtag,
    gtag as
    default,
};
