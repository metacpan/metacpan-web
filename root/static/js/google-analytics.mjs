window.dataLayer = window.dataLayer || [];

const gtag = (...args) => {
    window.dataLayer.push(args);
};

gtag('js', new Date());
gtag('config', 'G-E82Q2V8LVD', {
    cookie_flags: 'SameSite=Lax;Secure'
});

export {
    gtag,
    gtag as
    default,
};
