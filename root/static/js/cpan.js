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

function togglePanel(side) {
    var panel = $('#' + side + '-panel');
    var shower = $('#show-' + side + '-panel');
    if (!panel || !shower) return false;
    panel.toggle();
    shower.toggle();
    localStorage.setItem("hide_" + side + "_panel", (panel.css('display') == 'none' ? 1 : 0));
    return false;
}

function toggleTOC() {
    var container = $('#index-container');
    if (container.length == 0) return false;
    var visible = ! container.hasClass('hide-index');
    var index = $('#index');
    var newHeight = 0;
    if (!visible) {
        newHeight = index.get(0).scrollHeight;
    }
    index.animate({ height: newHeight }, {
        duration: 200,
        complete: function () {
            if (newHeight > 0) {
                index.css({ height: 'auto'});
            }
        }
    });
    localStorage.setItem('hideTOC', (visible ? 1 : 0));
    container.toggleClass('hide-index');
    return false;
}

$(document).ready(function () {
    $(".ttip").tooltip();

    SyntaxHighlighter.defaults['quick-code'] = false;
    SyntaxHighlighter.defaults['tab-size'] = 8;

    // Allow tilde in url (#1118). Orig: /\w+:\/\/[\w-.\/?%&=:@;#]*/g,
    SyntaxHighlighter.regexLib['url'] =  /\w+:\/\/[\w-.\/?%&=:@;#~]*/g;

    /**
    * Turns all package names into metacpan.org links within <a/> tags.
    * @param {String} code Input code.
    * @return {String} Returns code with </a> tags.
    */
    function processPackages(code)
    {
        var destination = document.location.href.match(/\/source\//) ? 'source' : 'pod',
            strip_delimiters = /((?:q[qw]?)?.)([A-Za-z0-9\:]+)(.*)/
            ;

        code = code.replace(/(<code class="pl keyword">(?:with|extends|use<\/code> <code class="pl plain">(?:parent|base|aliased))\s*<\/code>\s*<code class="pl string">)(.+?)(<\/code>)/g, function(m,prefix,pkg,suffix)
        {
            var match = null,
                mcpan_url
                ;

            if ( match = strip_delimiters.exec(pkg) )
            {
                prefix = prefix + match[1];
                pkg    = match[2];
                suffix = match[3] + suffix;
            }

            mcpan_url = '<a href="/' + destination + '/' + pkg + '">' + pkg + '</a>';
            return prefix + mcpan_url + suffix;
        });

        // Link our dependencies
        return code.replace(/(<code class="pl keyword">(use|package|require)<\/code> <code class="pl plain">)([A-Za-z0-9\:]+)(.*?<\/code>)/g, '$1<a href="/' + destination + '/$3">$3</a>$4');
    };

    var getCodeLinesHtml = SyntaxHighlighter.Highlighter.prototype.getCodeLinesHtml;
    SyntaxHighlighter.Highlighter.prototype.getCodeLinesHtml = function() {
      var html = getCodeLinesHtml.apply(this, arguments);
      return processPackages(html);
    };


    var source = $("#source");
    // if this is a source-code view with destination anchor
    if (source.length && source.html().length > 500000) {
        source.removeClass();
    }
    else if (source[0] && document.location.hash) {
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

    setTimeout(function() { SyntaxHighlighter.highlight(); }, 50);

    $('#signin-button').mouseenter(function () { $('#signin').show() });
    $('#signin').mouseleave(function () { $('#signin').hide() });

    $('table.tablesorter').each(function(){
        if (this.id == 'dashboard-dist-table') {
            return;
        }
        var sortid = (localStorage.getItem("tablesorter:"+ this.id) ||
          this.getAttribute('data-default-sort') || '0,0');
        sortid = JSON.parse("[" + sortid + "]");
        $(this).tablesorter({sortList: [sortid], textExtraction: function (node) {
            var $node = $(node);
            var sort = $node.attr("sort");
            if(!sort) return $node.text();
            if ($node.hasClass("date")) {
                return (new Date(sort)).getTime();
            } else {
                return sort;
            }
        }} );
    });

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

    $('#dashboard-dist-table').tablesorter({
        //debug: true,
        headers: {
          0: { sorter: false },
          1: { sorter: false },
          2: { sorter: false },
          4: { sorter: false },
          5: { sorter: false }
        }
    });

    $('.relatize').relatizeDate();

    // Search box: Feeling Lucky? Shift+Enter
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

    // Autocomplete issues:
    // #345/#396 Up/down keys should put selected value in text box for further editing.
    // #441 Allow more specific queries to send ("Ty", "Type::").
    // #744/#993 Don't select things if the mouse pointer happens to be over the dropdown when it appears.
    // Please don't steal ctrl-pg up/down.
    var search_input = $("#search-input");
    var ac_width = search_input.outerWidth();
    if (search_input.hasClass('top-input-form')) {
        ac_width += search_input.parents("form.search-form").first().find('.search-btn').first().outerWidth();
    }
    search_input.autocomplete({
        serviceUrl: '/search/autocomplete',
        // Wait for more typing rather than firing at every keystroke.
        deferRequestBy: 150,
        // If the autocomplete fires with a single colon ("type:") it will get no results
        // and anything else typed after that will never trigger another query.
        // Set 'preventBadQueries:false' to keep trying.
        preventBadQueries: false,
        dataType: 'json',
        lookupLitmit: 20,
        paramName: 'q',
        autoSelectFirst: false,
        // This simply caches the results of a previous search by url (so no reason not to).
        noCache: false,
        triggerSelectOnValidInput: false,
        maxHeight: 180,
        width: ac_width,
        transformResult: function (data) {
            var result = $.map(data, function (row) {
                return { 
                    data: row.documentation, 
                    value: row.documentation 
                };
            });
            var uniq = { };
            result   = $.grep(result, function (row) {
                uniq[row.value] = typeof(uniq[row.value]) == 'undefined' ? 0 : uniq[row.value];
                return uniq[row.value]++ < 1;
            });
            return { suggestions: result };
        },
        onSelect: function (suggestion) {
            document.location.href = '/pod/' + suggestion.value;
        }
    });

    // Disable the built-in hover events to work around the issue that
    // if the mouse pointer is over the box before it appears the event may fire erroneously.
    // Besides, does anybody really expect an item to be selected just by
    // hovering over it?  Seems unintuitive to me.  I expect anyone would either
    // click or hit a key to actually pick an item, and who's going to hover to
    // the item they want and then instead of just clicking hit tab/enter?
    $('.autocomplete-suggestions').off('mouseover.autocomplete');
    $('.autocomplete-suggestions').off('mouseout.autocomplete');

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

    $('.anchors').find('h1,h2,h3,h4,h5,h6,dt').each(function () {
      if (this.id) {
        $(this).prepend('<a href="#'+this.id+'" class="anchor"><span class="fa fa-bookmark black"></span></a>');
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

    $('.table.tablesorter th.header').on('click', function() {
        tableid = $(this).parents().eq(2).attr('id');
        setTimeout(function(){
            var sortParam  = $.getUrlVar('sort');
            if( sortParam != null ){
                sortParam  = sortParam.slice(2,5);
                localStorage.setItem( "tablesorter:" + tableid, sortParam );
            }
        }, 1000);
    });
    
    if($(".inline").find("button").hasClass("active")){
        $(".favorite").attr("title", "Remove from favorite");
    }
    else{
        $(".favorite").attr("title", "Add to favorite");
    }

    $('.dropdown-toggle').dropdown();

    var index = $("#index");
    if (index) {
        index.wrap('<div id="index-container"><div class="index-border"></div></div>');
        var container = index.parent().parent();

        var index_hidden = localStorage.getItem('hideTOC') == 1;
        index.before(
            '<div id="index-header"><b>Contents</b>'
            + ' [<button class="btn-link toggle-index"><span class="toggle-show">show</span><span class="toggle-hide">hide</span></button>]'
            + '</div>');

        $('.toggle-index').on('click', function (e) { e.preventDefault(); toggleTOC(); });
        if (index_hidden) {
            container.addClass("hide-index");
        }
    }

    ['right', 'left'].forEach(function (side) {
	    var panel = $(side + "-panel");
        if (panel) {
            var panel_hidden = localStorage.getItem("hide_" + side + "_panel") == 1;
            if (panel_hidden) {
                togglePanel(side);
            }
        }
    });

    $('a[href*="/search?"]').on('click', function() {
        var url = $(this).attr('href');
        var result = /size=(\d+)/.exec(url);
        if (result && result[1]) {
            localStorage.setItem('search_size', result[1]);
        }
    });
    var size = localStorage.getItem('search_size');
    if (size) {
        $('#size').val(size);
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

