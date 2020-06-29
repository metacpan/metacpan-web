
$(function() {
    var el = $('.nav-list').first();
    var topRow = $('.main-content').first();
    if (!el.length) return;
    var height = el.height();
    var content = $("div.content");
    if (!content.length) return;

    var right_panel = $("#right-panel");
    if (right_panel.length && right_panel.height() > content.height()) {
        content = right_panel;
    }

    if(height > content.height()) return;

    function alignSidebar(e) {
        var scrollTop = $(window).scrollTop();
        var screenHeight = $(window).height();
        var contentTop = content.offset().top;
        var contentHeight = content.height();
        if (height > contentHeight || scrollTop < contentTop + (height > screenHeight ? height - screenHeight : 0)) {
            el.addClass("sticky-panel-top").removeClass("sticky-panel-bottom sticky-panel-sticky");
        }
        else if (scrollTop + height > contentTop + contentHeight) {
            el.addClass("sticky-panel-bottom").removeClass("sticky-panel-top sticky-panel-sticky");
        }
        else if (height > screenHeight) {
            el.addClass("sticky-panel-bottom sticky-panel-sticky").removeClass("sticky-panel-top");
        }
        else {
            el.addClass("sticky-panel-sticky sticky-panel-top").removeClass("sticky-panel-bottom");
        }
    };

    $(window).scroll(alignSidebar);
    alignSidebar();
});
