$(function () {
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

    SyntaxHighlighter.highlight();
});
