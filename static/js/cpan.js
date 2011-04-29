var podVisible = true;

function togglePod(lines) {
    var toggle = podVisible ? 'none' : 'block';
    podVisible = !podVisible;
    if (!lines || !lines.length) return;
    for (var i = 0; i < lines.length; i++) {
        var start = lines[i][0],
        length = lines[i][1];
        var sourceC = document.querySelectorAll('.container')[0].children;
        var linesC = document.querySelectorAll('.gutter')[0].children;
        var x;
        for (x = start; x < start + length; x++) {
            sourceC[x].style.display = toggle;
            linesC[x].style.display = toggle;
        }

    }
}

$(document).ready(function() {

    SyntaxHighlighter.highlight();

    $('#search-input').keydown(function(event) {
        if (event.keyCode == '13' && event.shiftKey) {
            event.preventDefault();
            document.forms[0].q.name = 'lucky';
            document.forms[0].submit();
        }
    });

    var el = $('.search-bar');
    if (!el.length) return;
    var originalTop = el.offset().top; // store original top position
    $(window).scroll(function(e) {
        if ($(this).scrollTop() + 10 > originalTop) {
            el.css({
                'position': 'fixed',
                'top': '10px'
            });
        } else {
            el.css({
                'position': 'absolute',
                'top': originalTop
            });
        }
    });
});

function searchForNearest() {
    document.getElementById('busy').style.visibility = 'visible';
    navigator.geolocation.getCurrentPosition(function(pos) {
        document.location.href = '/mirrors?q=loc:' + pos.coords.latitude + ',' + pos.coords.longitude;
    },
    function() {},
    {
        maximumAge: 600000
    });
}

function disableTag(tag) {
    document.location.href = '/mirrors' + (document.location.search || '?q=') + ' ' + tag;
}