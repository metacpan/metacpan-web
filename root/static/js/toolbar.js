if( !/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent) ) {
    $(function() {
        var el = $('.nav-list.slidepanel').first();
        var topRow = $('.main-content').first();
        if (!el.length) return;
        var height = el.height();
        var content = $("div.content");
        if(height > content.height()) return;

        $(window).scroll(function(e) {
            var scrollTop = $(this).scrollTop();
            var contentTop = content.offset().top;
            var contentHeight = content.height();
            if (height > contentHeight) {
                el.addClass("sticky-panel-top").removeClass("sticky-panel-bottom sticky-panel-sticky");
            }
            else if (scrollTop + height > contentTop + contentHeight) {
                el.addClass("sticky-panel-bottom").removeClass("sticky-panel-top sticky-panel-sticky");
            }
            else if (scrollTop > contentTop) {
                el.addClass("sticky-panel-sticky").removeClass("sticky-panel-top sticky-panel-bottom");
            }
            else {
                el.addClass("sticky-panel-top").removeClass("sticky-panel-bottom sticky-panel-sticky");
            }
        });
    });
}
