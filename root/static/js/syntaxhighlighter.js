$(function () {
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
      html = html.replace(/^ /, "&#32;");
      html = getCodeLinesHtml.call(this, html, lineNumbers);
      return processPackages(html);
    };

    var getLineNumbersHtml = SyntaxHighlighter.Highlighter.prototype.getLineNumbersHtml;
    SyntaxHighlighter.Highlighter.prototype.getLineNumbersHtml = function() {
      var html = getLineNumbersHtml.apply(this, arguments);
      html = html.replace(/(<div[^>]*>\s*)(\d+)(\s*<\/div>)/g, '$1<a href="#L$2" id="L$2">$2</a>$3');
      return html;
    };


    var source = $("#source");
    if (source.length) {
        var lineMatch;
        var packageMatch
        if (source.html().length > 500000) {
            source.children('code').removeClass();
        }
        else if ( lineMatch = document.location.hash.match(/^#L(\d+)$/) ) {
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

    /* set perl as the default type in pod */
    $(".pod pre > code").each(function(index, source) {
        var have_lang;
        if (source.className) {
            var classes = source.className.split(/\s+/);
            for (var i = 0; i < classes.length; i++) {
                if (classes[i].match(/^language-(.*)/)) {
                    return;
                }
            }
        }
        source.className = 'language-perl';
    });

    $(".content pre > code").each(function(index, source) {
        var code = $(source);
        var pre = code.parent();

        var config = {
            'gutter'      : false,
            'toolbar'     : false,
            'quick-code'  : false,
            'tab-size'    : 8
        };
        if (source.className) {
            var classes = source.className.split(/\s+/);
            for (var i = 0; i < classes.length; i++) {
                var res = classes[i].match(/^language-(.*)/);
                if (res) {
                    config.brush = res[1];
                }
            }
        }
        if (!config.brush) {
            return;
        }

        if (pre.hasClass('line-numbers')) {
            config.gutter = true;
        }
        var first_line = pre.attr('data-start');
        if (first_line) {
            config['first-line'] = first_line;
        }
        var lines = pre.attr('data-line');
        if (lines) {
            lines = lines.split(/,/);
            var all_lines = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                var res = line.match(/(\d+)-(\d+)/);
                if (res) {
                    for (var l = res[1]; l <= res[2]; l++) {
                        all_lines.push(l);
                    }
                }
                else {
                    all_lines.push(line);
                }
            }
            config.highlight = all_lines;
        }

        SyntaxHighlighter.highlight(config, source);
    });
});
