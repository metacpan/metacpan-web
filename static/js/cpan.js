$.fn.textWidth = function(){
  var html_org = $(this).html();
  var html_calc = '<span>' + html_org + '</span>'
  $(this).html(html_calc);
  var width = $(this).find('span:first').width();
  $(this).html(html_org);
  return width;
};

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

function toggleTOC() {
    var index = $('#index');
    if(!index) return false;
    var visible = index.is(':visible');
    visible ? index.hide() : index.show();
    visible ? $.cookie("hideTOC", 1, { expires: 999, path: '/' }) : $.cookie("hideTOC", 0, { expires: 999, path: '/' });
    return false;
}

$(document).ready(function() {
    SyntaxHighlighter.defaults['quick-code'] = false;
    SyntaxHighlighter.highlight();

    $('.relatize').relatizeDate();

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

    var items = $('.ellipsis');
      for(var i = 0; i < items.length; i++) {
        var element = $(items[i]);
        var boxWidth = element.width();
        var textWidth = element.textWidth();
        var text = element.text();
        var textLength = text.length;
        if(textWidth <= boxWidth) continue;
        var parts = [text.substr(0, Math.floor(textLength/2)), text.substr(Math.floor(textLength/2), textLength)];
        while(element.textWidth() > boxWidth) {
          if(textLength % 2) {
            parts[0] = parts[0].substr(0, parts[0].length-1);
          } else {
            parts[1] = parts[1].substr(1, parts[1].length);
          }
          textLength--;
          element.html(parts.join('…'));
        }
      }
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