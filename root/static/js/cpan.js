/* jshint white: true, lastsemic: true */

$.fn.textWidth = function () {
    var html_org = $(this).html();
    var html_calc = '<span>' + html_org + '</span>';
    $(this).html(html_calc);
    var width = $(this).find('span:first').width();
    $(this).html(html_org);
    return width;
};

$.extend({
    getUrlVars: function () {
        var vars = {}, hash;
        var indexOfQ = window.location.href.indexOf('?');
        if (indexOfQ == -1) return vars;
        var hashes = window.location.href.slice(indexOfQ + 1).split('&');
        $.each(hashes, function (idx, hash) {
            var kv = hash.split('=');
            vars[kv[0]] = kv[1];
        });
        return vars;
    },
    getUrlVar: function (name) {
        return $.getUrlVars()[name];
    }
});

var podVisible = false;

function togglePod(lines) {
    var toggle = podVisible ? 'none' : 'block';
    podVisible = !podVisible;
    if (!lines || !lines.length) return;
    for (var i = 0; i < lines.length; i++) {
        var start = lines[i][0],
        length = lines[i][1];
        var sourceC = $('.container')[0].children;
        var linesC = $('.gutter')[0].children;
        var x;
        for (x = start; x < start + length; x++) {
            sourceC[x].style.display = toggle;
            linesC[x].style.display = toggle;
        }

    }
}

function toggleTOC() {
    var index = $('#index');
    if (!index) return false;
    var visible = index.is(':visible');
    visible ? index.hide() : index.show();
    visible ? $.cookie("hideTOC", 1, { expires: 999, path: '/' }) : $.cookie("hideTOC", 0, { expires: 999, path: '/' });
    return false;
}

$(document).ready(function () {
    $(".ttip").tooltip();

    SyntaxHighlighter.defaults['quick-code'] = false;
    SyntaxHighlighter.defaults['tab-size'] = 8;

    // Allow tilde in url (#1118). Orig: /\w+:\/\/[\w-.\/?%&=:@;#]*/g,
    SyntaxHighlighter.regexLib['url'] =  /\w+:\/\/[\w-.\/?%&=:@;#~]*/g;

    var source = $("#source");
    // if this is a source-code view with destination anchor
    if (source[0] && document.location.hash) {
        // check for 'L{number}' anchor in URL and highlight and jump
        // to that line.
        var lineMatch = document.location.hash.match(/^#L(\d+)$/);
        if (lineMatch) {
            SyntaxHighlighter.defaults['highlight'] = [lineMatch[1]];
        }
        else {
            // check for 'P{encoded_package_name}' anchor, convert to
            // line number (if possible), and then highlight and jump
            // as long as the matching line is not the first line in
            // the code.
            var packageMatch = document.location.hash.match(/^#P(\S+)$/);
            if (packageMatch) {
                var decodedPackageMatch = decodeURIComponent(packageMatch[1]);
                var leadingSource = source.html().split("package " + decodedPackageMatch + ";");
                var lineCount = leadingSource[0].split("\n").length;
                if (leadingSource.length > 1 && lineCount > 1) {
                    SyntaxHighlighter.defaults['highlight'] = [lineCount];
                    document.location.hash = "#L" + lineCount;
                }
                else {
                    // reset the anchor portion of the URL (it just looks neater).
                    document.location.hash = '';
                }
            }
        }
    }

    SyntaxHighlighter.highlight();
    
    $('#signin-button').mouseenter(function () { $('#signin').show() });
    $('#signin').mouseleave(function () { $('#signin').hide() });
    if (typeof defaultSort == "undefined") defaultSort = [[0, 0]];
    $('.tablesorter').tablesorter({sortList: defaultSort, widgets: ['zebra'], textExtraction: function (node) {
        var $node = $(node);
        var sort = $node.attr("sort");
        if(!sort) return node.innerHTML;
        if ($node.hasClass("date")) {
            return (new Date(sort)).getTime();
        } else {
            return sort;
        }
    }} );

    $('.tablesorter.remote th.header').each(function () {
        $(this).unbind('click');
        $(this).click(function (event) {
            var $cell = $(this);
            var params = $.getUrlVars();
            params.sort = '[[' + this.column + ',' + this.count++ % 2 + ']]';
            var query = $.param(params);
            var url = window.location.href.replace(window.location.search, '');
            window.location.href = url + '?' + query;
        });
    });

    $('.relatize').relatizeDate();

    $('#search-input').keyup(function (event) {
        // if up/down arrow is released
        if (event.keyCode == '38' || event.keyCode == '40') {
            // get the currently hovered query
            var query = $('.ac_over').text();
            if (query) {
                $('#search-input').val(query);
            }
        }
    });

    $('#search-input').keydown(function (event) {
        if (event.keyCode == '13' && event.shiftKey) {
            event.preventDefault();

            /* To make this a lucky search we have to create a new
             * <input> element to pass along lucky=1.
             */
            var luckyField = document.createElement("input");
            luckyField.type = 'hidden';
            luckyField.name = 'lucky';
            luckyField.value = '1';
            document.forms[0].appendChild(luckyField);

            document.forms[0].submit();
        }
    });

    $("#search-input").autocomplete('/search/autocomplete', {
        dataType: 'json',
        delay: 100,
        max: 20,
        selectFirst: false,
        width: $("#search-input").width() + 5,
        parse: function (data) {
            var result = $.map(data, function (row) {
                return {
                    data: row,
                    value: row.documentation,
                    result: row.documentation
                };
            });
            var uniq = {};
            result = $.grep(result, function (row) {
                uniq[row.result] = typeof(uniq[row.result]) == 'undefined' ? 0 : uniq[row.result];
                return uniq[row.result]++ < 1;
            });
            return result;
        },
        formatItem: function (item) {
            return item.documentation;
        }
    }).result(function(e, item) {
        document.location.href = '/pod/'+ item.documentation;
    });

    $('#search-input.autofocus').focus();

    var items = $('.ellipsis');
    for (var i = 0; i < items.length; i++) {
        var element = $(items[i]);
        var boxWidth = element.width();
        var textWidth = element.textWidth();
        var text = element.text();
        var textLength = text.length;
        if (textWidth <= boxWidth) continue;
        var parts = [text.substr(0, Math.floor(textLength / 2)), text.substr(Math.floor(textLength / 2), textLength)];
        while (element.textWidth() > boxWidth) {
            if (textLength % 2) {
                parts[0] = parts[0].substr(0, parts[0].length - 1);
            } else {
                parts[1] = parts[1].substr(1, parts[1].length);
            }
            textLength--;
            element.html(parts.join('…'));
        }
    }

    $('.pod').find('h1,h2,h3,h4,h5,h6,dt').each(function () {
      if (this.id) {
        $(this).prepend('<a href="#'+this.id+'" class="anchor"><i class="icon-bookmark"></i></a>');
      }
    });

    var module_source_href = $('#source-link').attr('href');
    if(module_source_href) {
        $('#pod-error-detail dt').each(function() {
            var $dt = $(this);
            var link_text = $dt.text();
            var capture = link_text.match(/Around line (\d+)/);
            $dt.html(
                $('<a />').attr('href', module_source_href + '#L' + capture[1])
                    .text(link_text)
            );
        });
    }
    $('#pod-errors').addClass('collapsed');
    $('#pod-errors p.title').click(function() { $(this).parent().toggleClass('collapsed'); });
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

function toggleProtocol(tag) {
    var l = window.location;
    var s = l.search ? l.search : '?q=';
    if (! s.match(tag) ) {
        s += " " + tag
    } else {
        // Toggle that protocol filter off again
        s = s.replace(tag, "");
    }
    s = s.replace(/=(%20|\s)+/, '='); // cleanup lingering space if any :P
    s = s.replace(/(%20|\s)+$/, "");
    l.href = '/mirrors' + s;
}

function logInPAUSE(a) {
    if (!a.href.match(/pause/))
        return true;
    var id = prompt('Please enter your PAUSE ID:');
    if (id) document.location.href = a.href + '&id=' + id;
    return false;
}

function favDistribution(form) {
    form = $(form);
    var data = form.serialize();
    $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: data,
        success: function () {
            var button = form.find('button');
            button.toggleClass('active');
            var counter = button.find('span');
            var count = counter.text();
            if (button.hasClass('active')) {
                counter.text(count ? parseInt(count, 10) + 1 : 1);
                form.append('<input type="hidden" name="remove" value="1">');
                if (!count)
                    button.toggleClass('highlight');
            } else {
                counter.text(parseInt(count, 10) - 1);
                form.find('input[name="remove"]').remove();
                if (counter.text() === 0) {
                    counter.text("");
                    button.toggleClass('highlight');
                }
            }
        },
        error: function () {
            if (confirm("You have to complete a Captcha in order to ++.")) {
                document.location.href = "/account/turing";
            }
        }
    });
    return false;
}

$(document).on('keydown', function (e) {
        if (e.keyCode === 27) { 
            $( "#dependencies-graph" ).hide(); 
            $( ".modal-backdrop" ).hide();
        } 
});
