$(function () {
    // convert a string like "1,3-5,7" into an array [1,3,4,5,7]
    function parseLines (lines) {
        lines = lines.split(/\s*,\s*/);
        var all_lines = [];
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            var res = line.match(/^\s*(\d+)\s*(?:-\s*(\d+)\s*)?$/);
            if (res) {
                var start = res[1]*1;
                var end = (res[2] || res[1])*1;
                for (var l = start; l <= end; l++) {
                    all_lines.push(l);
                }
            }
        }
        return all_lines;
    }

    function findLines (el, lines) {
        var selector = $.map(
            parseLines(lines),
            function (line) { return '.number' + line }
        ).join(', ');
        return el.find('.syntaxhighlighter .line').filter(selector);
    }

    var hashLines = /^#L(\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)$/;

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

        code = code.replace(/(<code class="p(?:er)?l keyword">(?:with|extends|use<\/code> <code class="p(?:el)?l plain">(?:parent|base|aliased))\s*<\/code>\s*<code class="p(?:er)?l string">)(.+?)(<\/code>)/g, function(m,prefix,pkg,suffix)
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
        return code.replace(/(<code class="p(?:er)?l keyword">(use|package|require)<\/code> <code class="p(?:er)?l plain">)([A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*)(.*?<\/code>)/g, '$1<a href="/' + destination + '/$3">$3</a>$4');
    };

    var getCodeLinesHtml = SyntaxHighlighter.Highlighter.prototype.getCodeLinesHtml;
    SyntaxHighlighter.Highlighter.prototype.getCodeLinesHtml = function(html, lineNumbers) {
      // the syntax highlighter has a bug that strips spaces from the first line.
      // replace any leading whitespace with an entity, preventing that.
      html = html.replace(/^ /, "&#32;");
      html = html.replace(/^\t/, "&#9;");
      html = getCodeLinesHtml.call(this, html, lineNumbers);
      return processPackages(html);
    };


    var source = $("#source");
    if (source.length) {
        var lineMatch;
        var packageMatch;
        // avoid highlighting excessively large blocks of code as they will take
        // too long, causing browsers to lag and offer to kill the script
        if (source.html().length > 500000) {
            source.children('code').removeClass();
        }
        // save highlighted lines in an attribute, to be used later
        else if ( lineMatch = document.location.hash.match(hashLines) ) {
            source.attr('data-line', lineMatch[1]);
        }
        // check for 'P{encoded_package_name}' anchor, convert to
        // line number (if possible), and then highlight and jump
        // as long as the matching line is not the first line in
        // the code.
        else if ( packageMatch = document.location.hash.match(/^#P(\S+)$/) ) {
            var decodedPackageMatch = decodeURIComponent(packageMatch[1]);
            var leadingSource = source.text().split("package " + decodedPackageMatch + ";");
            var lineCount = leadingSource[0].split("\n").length;
            if (leadingSource.length > 1 && lineCount > 1) {
                source.attr('data-line', lineCount);
                document.location.hash = "#L" + lineCount;
            }
            else {
                // reset the anchor portion of the URL (it just looks neater).
                document.location.hash = '';
            }
        }
    }

    // on pod pages, set the language to perl if no other language is set
    $(".pod pre > code").each(function(index, code) {
        var have_lang;
        if (code.className && code.className.match(/(?:\s|^)language-\S+/)) {
            return;
        }
        $(code).addClass('language-perl');
    });

    $(".content pre > code").each(function(index, code) {
        var pre = $(code).parent();

        var config = {
            'gutter'      : false,
            'toolbar'     : false,
            'quick-code'  : false,
            'tab-size'    : 8
        };
        if (code.className) {
            var res = code.className.match(/(?:\s|^)language-(\S+)/);
            if (res) {
                config.brush = res[1];
            }
        }
        if (!config.brush) {
            return;
        }

        if (pre.hasClass('line-numbers')) {
            config.gutter = true;
        }
        // starting line number can be provided by an attribute
        var first_line = pre.attr('data-start');
        if (first_line) {
            config['first-line'] = first_line;
        }
        // highlighted lines can be provided by an attribute
        var lines = pre.attr('data-line');
        if (lines) {
            config.highlight = parseLines(lines);
        }

        // highlighter strips leading blank lines, throwing off line numbers.
        // add a blank line for the highlighter to strip
        var html = $(code).html();
        if (html.match(/^ *\n/)) {
          $(code).html("\n " + html);
        }

        SyntaxHighlighter.highlight(config, code);

        var pod_lines = pre.attr('data-pod-lines');
        if (pod_lines) {
            findLines(pre, pod_lines).addClass('pod-line');
        }
    });

    if (source.length) {
        // on the source page, make line numbers into links
        source.find('.syntaxhighlighter .gutter .line').each(function(i, el) {
            var line = $(el);
            var res;
            if (res = line.attr('class').match(/(^|\s)number(\d+)(\s|$)/)) {
                var linenr = res[2];
                var id = 'L' + linenr;
                line.contents().wrap('<a href="#'+id+'" id="'+id+'"></a>');
                var link = line.children('a');
                link.click(function(e) {
                    // normally the browser would update the url and scroll to
                    // the the link.  instead, update the hash ourselves, but
                    // unset the id first so it doesn't scroll
                    e.preventDefault();
                    link.removeAttr('id');
                    document.location.hash = '#' + id;
                    link.attr('id', id);
                });
            }
        });

        // the line ids are added by javascript, so the browser won't have
        // scrolled to it.  also, highlight ranges don't correspond to exact
        // ids.  do the initial scroll ourselves.
        var res;
        if (res = document.location.hash.match(/^(#L\d+)(-|,|$)/)) {
            var el = $(res[1]);
            $('html, body').scrollTop(el.offset().top);
        }

        // if someone changes the url hash manually, update the highlighted lines
        $(window).on('hashchange', function() {
            var lineMatch;
            if (lineMatch = document.location.hash.match(hashLines) ) {
                source.attr('data-line', lineMatch[1]);
                source.find('.highlighted').removeClass('highlighted');
                findLines(source, lineMatch[1]).addClass('highlighted');
            }
        });
    }
});

function togglePod() {
    $('.pod-toggle').toggleClass('pod-hidden');
}
