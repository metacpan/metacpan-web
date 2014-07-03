if( !/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent) ) {
    $(function() {
        var el = $('.nav-list').first();
        var topRow = $('.col-md-12').first();
        if (!el.length) return;
        var originalTop = el.offset().top - topRow.offset().top; // store original top position - top content
        var height = el.height();
        var contentHeight = $("div.content").height();
        if(height > contentHeight) return;
        $(window).scroll(function(e) {
            var screenHeight = $(window).height();
            if ($(this).scrollTop() > originalTop + (screenHeight - height < 0 ? height - screenHeight : 0 )) {
                el.css({
                    position: 'fixed',
                    top: (screenHeight - height < 0 ? screenHeight - height : 0 ) + 'px'
                });
            } else {
                el.css({
                    position: 'absolute',
                    top: originalTop
                });
            }
        });
    });
}