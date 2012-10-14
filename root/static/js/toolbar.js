$(function() {
    var el = $('.search-bar');
    if (!el.length) return;
    var originalTop = el.offset().top; // store original top position
    var height = el.height();
    $(window).scroll(function(e) {
        var screenHeight = $(window).height();
        if ($(this).scrollTop() > originalTop + (screenHeight - height < 0 ? height - screenHeight + 10 : -10 )) {
            el.css({
                'position': 'fixed',
                'top': (screenHeight - height < 0 ? screenHeight - height - 10 : 10 ) + 'px'
            });
        } else {
            el.css({
                'position': 'absolute',
                'top': originalTop
            });
        }
    });
});