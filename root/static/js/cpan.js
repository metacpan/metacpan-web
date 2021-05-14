/* jshint white: true, lastsemic: true */

// Store global data in this object
var MetaCPAN = {};

// provide localStorage shim to work around https://bugzilla.mozilla.org/show_bug.cgi?id=748620
try {
    MetaCPAN.storage = window.localStorage;
} catch (e) {}
if (!MetaCPAN.storage) {
    MetaCPAN.storage = {
        getItem: function(k) {
            return this["_" + k];
        },
        setItem: function(k, v) {
            return this["_" + k] = v;
        },
    };
}

$.extend({
    getUrlVars: function() {
        var vars = {},
            hash;
        var indexOfQ = window.location.href.indexOf('?');
        if (indexOfQ == -1) return vars;
        var hashes = window.location.href.slice(indexOfQ + 1).split('&');
        $.each(hashes, function(idx, hash) {
            var kv = hash.split('=');
            vars[kv[0]] = decodeURIComponent(kv[1]);
        });
        return vars;
    },
    getUrlVar: function(name) {
        return $.getUrlVars()[name];
    }
});

function togglePanel(side, visible) {
    var elements = $('#' + side + '-panel-toggle').add($('#' + side + '-panel'));
    var className = 'panel-hide';
    if (typeof visible == "undefined") {
        visible = elements.first().hasClass(className);
    }
    if (visible) {
        elements.removeClass(className);
    } else {
        elements.addClass(className);
    }
    MetaCPAN.storage.setItem("hide_" + side + "_panel", visible ? 0 : 1);
    return false;
}

function toggleTOC() {
    var container = $('#index-container');
    if (container.length == 0) return false;
    var visible = !container.hasClass('hide-index');
    var index = $('#index');
    var newHeight = 0;
    if (!visible) {
        newHeight = index.get(0).scrollHeight;
    }
    index.animate({
        height: newHeight
    }, {
        duration: 200,
        complete: function() {
            if (newHeight > 0) {
                index.css({
                    height: 'auto'
                });
            }
        }
    });
    MetaCPAN.storage.setItem('hideTOC', (visible ? 1 : 0));
    container.toggleClass('hide-index');
    return false;
}

function setFavTitle(button) {
    button.attr('title', button.hasClass('active') ? 'Remove from favorites' : 'Add to favorites');
    return;
}

$(document).ready(function() {

    // User customisations
    processUserData();

    $(".ttip").tooltip();

    $('.help-btn').each(function() {
        $(this).click(function(event) {
            $('#keyboard-shortcuts').modal();
            event.preventDefault();
        })
    });

    // Global keyboard shortcuts
    Mousetrap.bind('?', function() {
        $('#keyboard-shortcuts').modal();
    });
    Mousetrap.bind('s', function(e) {
        $('#search-input').focus();
        e.preventDefault();
    });

    // install a default handler for 'g s' for non pod pages
    Mousetrap.bind('g s', function(e) {});

    $('a[data-keyboard-shortcut]').each(function(index, element) {
        Mousetrap.bind($(element).data('keyboard-shortcut'), function() {
            window.location = $(element).attr('href');
        });
    });

    $('table.tablesorter').each(function() {
        var table = $(this);

        var cfg = {
            textExtraction: function(node) {
                var $node = $(node);
                var sort = $node.attr("sort");
                if (!sort) return $node.text();
                if ($node.hasClass("date")) {
                    return (new Date(sort)).getTime();
                } else {
                    return sort;
                }
            },
            headers: {}
        };

        var sortable = [];
        table.find('thead th').each(function(i, el) {
            var header = {};
            if ($(el).hasClass('no-sort')) {
                header.sorter = false;
            } else {
                sortable.push(i);
            }
            cfg.headers[i] = header;
        });

        var sortid;
        if (table.attr('id')) {
            sortid = MetaCPAN.storage.getItem("tablesorter:" + table.attr('id'));
        }
        if (!sortid && table.attr('data-default-sort')) {
            sortid = table.attr('data-default-sort');
        }
        if (!sortid) {
            var match = /[?&]sort=\[\[([0-9,]+)\]\]/.exec(window.location.search);
            if (match) {
                sortid = decodeURIComponent(match[1]);
            } else {
                sortid = '0,0';
            }
        }
        try {
            sortid = JSON.parse('[' + sortid + ']');
        } catch (e) {
            sortid = [0, 0];
        }

        var sortCol;
        var sortHeader = cfg.headers[sortid[0]];
        if (typeof sortHeader === 'undefined') {
            sortLCol = [sortable[0], 0];
        } else if (sortHeader.sorter == false) {
            sortCol = [sortable[0], 0];
        } else {
            sortCol = sortid;
        }
        cfg.sortList = [sortCol];

        table.tablesorter(cfg);
    });

    $('.tablesorter.remote th.header').each(function() {
        $(this).unbind('click');
        $(this).click(function(event) {
            var $cell = $(this);
            var params = $.getUrlVars();
            params.sort = '[[' + this.column + ',' + this.count++ % 2 + ']]';
            var query = $.param(params);
            var url = window.location.href.replace(window.location.search, '');
            window.location.href = url + '?' + query;
        });
    });

    $('.relatize').relatizeDate();

    // Search box: Feeling Lucky? Shift+Enter
    $('#search-input').keydown(function(event) {
        if (event.keyCode == '13' && event.shiftKey) {
            event.preventDefault();

            /* To make this a lucky search we have to create a new
             * <input> element to pass along lucky=1.
             */
            var luckyField = document.createElement("input");
            luckyField.type = 'hidden';
            luckyField.name = 'lucky';
            luckyField.value = '1';

            var form = event.target.form;
            form.appendChild(luckyField);
            form.submit();
        }
    });

    // Autocomplete issues:
    // #345/#396 Up/down keys should put selected value in text box for further editing.
    // #441 Allow more specific queries to send ("Ty", "Type::").
    // #744/#993 Don't select things if the mouse pointer happens to be over the dropdown when it appears.
    // Please don't steal ctrl-pg up/down.
    var search_input = $("#search-input");
    var input_group = search_input.parent('.input-group');
    var ac_width = (input_group.length ? input_group : search_input).outerWidth();
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
        onSelect: function(suggestion) {
            if (suggestion.data.type == 'module') {
                document.location.href = '/pod/' + suggestion.data.module;
            } else if (suggestion.data.type == 'author') {
                document.location.href = '/author/' + suggestion.data.id;
            }
        }
    });
    var ac = search_input.autocomplete();
    var formatResult = ac.options.formatResult;
    ac.options.formatResult = function(suggestion, currentValue) {
        var out = formatResult(suggestion, currentValue);
        if (suggestion.data.type == 'author') {
            return "<span class=\"suggest-author-label\">Author:</span> " + out;
        }
        return out;
    };


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
        var element = items[i];
        var text = element.textContent;

        // try to find a reasonable place to cut to allow mid-abbreviation.
        // we want to cut "near" the middle, but prefer on a boundary.
        var cut = Math.floor(text.length / 5 * 3);
        var start_text = text.substr(0, cut);
        var end_text = text.substr(cut);
        var res = start_text.match(/^(.*[- :])(.*?)$/);
        if (res && res[1].length > text.length / 4) {
            start_text = res[1];
            end_text = res[2] + end_text;
        }

        var start = document.createElement('span');
        start.appendChild(document.createTextNode(start_text));
        var end = document.createElement('span');
        end.appendChild(document.createTextNode(end_text));
        $(element).empty();
        element.appendChild(end);
        start.style.maxWidth = 'calc(100% - ' + end.clientWidth + 'px)';
        element.insertBefore(start, end);
    }

    function create_anchors(top) {
        top.find('h1,h2,h3,h4,h5,h6,dt').each(function() {
            if (this.id) {
                $(document.createElement('a')).attr('href', '#' + this.id).addClass('anchor').append(
                    $(document.createElement('span')).addClass('fa fa-bookmark black')
                ).prependTo(this);
            }
        });
    }
    create_anchors($('.anchors'));

    var module_source_href = $('#source-link').attr('href');
    if (module_source_href) {
        $('.pod-errors-detail dt').each(function() {
            var $dt = $(this);
            var link_text = $dt.text();
            var capture = link_text.match(/Around line (\d+)/);
            $dt.html(
                $('<a />').attr('href', module_source_href + '#L' + capture[1])
                .text(link_text)
            );
        });
    }
    $('.pod-errors').addClass('collapsed');
    $('.pod-errors > p:first-child').click(function() {
        $(this).parent().toggleClass('collapsed');
    });

    $('table.tablesorter th.header').on('click', function() {
        tableid = $(this).parents().eq(2).attr('id');
        setTimeout(function() {
            var sortParam = $.getUrlVar('sort');
            if (sortParam != null) {
                sortParam = sortParam.slice(2, sortParam.length - 2);
                MetaCPAN.storage.setItem("tablesorter:" + tableid, sortParam);
            }
        }, 1000);
    });

    setFavTitle($('.breadcrumbs .favorite'));

    $('.dropdown-toggle').dropdown();

    function format_index(index) {
        index.wrap('<div id="index-container"><div class="index-border"></div></div>');
        var container = index.parent().parent();

        var index_hidden = MetaCPAN.storage.getItem('hideTOC') == 1;
        index.before(
            '<div class="index-header"><b>Contents</b>' + ' [ <button class="btn-link toggle-index"><span class="toggle-show">show</span><span class="toggle-hide">hide</span></button> ]' + ' <button class="btn-link toggle-index-right"><i class="fa fa-toggle-right"></i><i class="fa fa-toggle-left"></i></button>' + '</div>');

        $('.toggle-index').on('click', function(e) {
            e.preventDefault();
            toggleTOC();
        });
        if (index_hidden) {
            container.addClass("hide-index");
        }

        $('.toggle-index-right').on('click', function(e) {
            e.preventDefault();
            MetaCPAN.storage.setItem('rightTOC', container.hasClass('pull-right') ? 0 : 1);
            container.toggleClass('pull-right');
        });
        if (MetaCPAN.storage.getItem('rightTOC') == 1) {
            container.addClass("pull-right");
        }
    }
    var index = $("#index");
    if (index.length) {
        format_index(index);
    }

    ['right'].forEach(function(side) {
        var panel = $('#' + side + "-panel");
        if (panel.length) {
            var panel_visible = MetaCPAN.storage.getItem("hide_" + side + "_panel") != 1;
            togglePanel(side, panel_visible);
        }
    });

    $('a[href*="/search?"]').on('click', function() {
        var url = $(this).attr('href');
        var result = /size=(\d+)/.exec(url);
        if (result && result[1]) {
            MetaCPAN.storage.setItem('search_size', result[1]);
        }
    });
    var size = MetaCPAN.storage.getItem('search_size');
    if (size) {
        $('#search-size').val(size);
    }

    // TODO use a more specific locator for /author/PAUSID/release ?
    set_page_size('a[href*="/releases"]', 'releases_page_size');
    set_page_size('a[href*="/recent"]', 'recent_page_size');
    set_page_size('a[href*="/requires"]', 'requires_page_size');

    var changes = $('#last-changes');
    var changes_inner = $('#last-changes-container');
    var changes_toggle = $("#last-changes-toggle");
    changes.addClass(['collapsable', 'collapsed']);
    var changes_content_height = Math.round(changes_inner.prop('scrollHeight'));
    var changes_ui_height = Math.round(changes_inner.height() + changes_toggle.height());
    if (changes_content_height <= changes_ui_height) {
        changes.removeClass(['collapsable', 'collapsed']);
    }

    var pod2html_form = $('#metacpan-pod-renderer-form');
    var pod2html_text = $('[name="pod"]', pod2html_form);
    var pod2html_update = function(pod) {
        if (!pod) {
            pod = pod2html_text.get(0).value;
        }
        var submit = pod2html_form.find('input[type="submit"]');
        submit.attr("disabled", "disabled");
        var rendered = $('#metacpan-pod-renderer-output');
        var loading = $('#metacpan-pod-renderer-loading');
        var error = $('#metacpan-pod-renderer-error');
        rendered.hide();
        rendered.html('');
        loading.show();
        error.hide();
        document.title = "Pod Renderer - metacpan.org";
        $.ajax({
            url: '/pod2html',
            method: 'POST',
            data: {
                pod: pod,
                raw: true
            },
            success: function(data, stat, req) {
                rendered.html(data);
                loading.hide();
                error.hide();
                var res = $('#NAME + p').text().match(/^([^-]+?)\s*-\s*(.*)/);
                if (res) {
                    var title = res[0];
                    var abstract = res[1];
                    document.title = "Pod Renderer - " + title + " - metacpan.org";
                }
                var index = $("#index", rendered);
                if (index.length) {
                    format_index(index);
                }
                create_anchors(rendered);
                rendered.show();
                submit.removeAttr("disabled");
            },
            error: function(data, stat) {
                rendered.hide();
                loading.hide();
                error.html('Error rendering POD' +
                    (data && data.length ? ' - ' + data : ''));
                error.show();
                submit.removeAttr("disabled");
            }
        });
    };
    if (window.FileReader) {
        $('input[type="file"]', pod2html_form).on('change', function(e) {
            var files = this.files;
            for (var i = 0; i < files.length; i++) {
                var file = files[i];
                var reader = new FileReader();
                reader.onload = function(e) {
                    pod2html_text.get(0).value = e.target.result;
                    pod2html_update(e.target.result);
                };
                reader.readAsText(file);
            }
            this.value = null;
        });
    }
    pod2html_form.on('submit', function(e) {
        e.preventDefault();
        e.stopPropagation();
        pod2html_update();
    });

    var renderer = $(".metacpan-pod-renderer")

    var dragTimer;
    renderer.on("dragover", function(event) {
        event.preventDefault();
        if (dragTimer) {
            window.clearTimeout(dragTimer);
        }
        dragTimer = window.setTimeout(function() {
            renderer.removeClass("dragging");
            window.clearTimeout(dragTimer);
            dragTimer = null;
        }, 500);
    });

    $(document).on("dragenter", function(event) {
        renderer.addClass("dragging");
    });

    renderer.on("drop", function(event) {
        event.preventDefault();
        event.stopPropagation();
        renderer.removeClass("dragging");
        if (dragTimer) {
            window.clearTimeout(dragTimer);
            dragTimer = null;
        }
        var reader = new FileReader();
        reader.onload = function(e) {
            pod2html_text.get(0).value = e.target.result;
            pod2html_update(e.target.result);
        };
        reader.readAsText(event.originalEvent.dataTransfer.files[0]);
    });
});

function set_page_size(selector, storage_name) {
    $(selector).each(function() {
        var url = this.href;
        var result = /[&;?]size=(\d+)(?:$|[&;])/.exec(url);
        var size;
        if (result && result[1]) {
            size = result[1];
            $(this).click(function() {
                MetaCPAN.storage.setItem(storage_name, size);
                return true;
            });
        } else if (size = MetaCPAN.storage.getItem(storage_name)) {
            if (/\?/.exec(url)) {
                this.href += '&size=' + size;
            } else {
                this.href += '?size=' + size;
            }
        }
        return true;
    });
}

function processUserData() {

    // Could do some fancy localStorage thing here
    // but as the user favs data is cached at fastly
    // not worth the effort yet

    // TODO: get this working to save hits and 403's
    // if(document.cookie.match('metacpan_secure')) {
    //   getFavDataFromServer();
    // } else {
    //   // Can't be logged in
    //   $('.logged_out').css('display', 'inline');
    // }

    getFavDataFromServer();
}

function showUserData(fav_data) {
    // User is logged in, so show it
    $('.logged_in').css('display', 'inline');

    // process users current favs
    $.each(fav_data.faves, function(index, value) {
        var distribution = value.distribution;

        // On the page... make it deltable and styled as 'active'
        var fav_display = $('#' + distribution + '-fav');

        if (fav_display.length) {
            fav_display.find('input[name="remove"]').val(1);
            var button = fav_display.find('button');
            button.addClass('active');
            setFavTitle(button);
        }

    });

}

function getFavDataFromServer() {
    $.ajax({
        type: 'GET',
        url: '/account/login_status',
        success: function(databack) {
            if (databack.logged_in) {
                showUserData(databack);
            } else {
                $('.logged_out').css('display', 'inline');
            }
        },
        error: function() {
            // Can't be logged in, should be getting 403
            $('.logged_out').css('display', 'inline');
        }
    });
    return true;
}

function favDistribution(form) {
    form = $(form);
    var data = form.serialize();
    $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: data,
        success: function() {
            var button = form.find('button');
            button.toggleClass('active');
            setFavTitle(button);
            var counter = button.find('span');
            var count = counter.text();
            if (button.hasClass('active')) {
                counter.text(count ? parseInt(count, 10) + 1 : 1);
                // now added let users remove
                form.find('input[name="remove"]').val(1);
                if (!count)
                    button.toggleClass('highlight');
            } else {
                // can't delete what's already deleted
                form.find('input[name="remove"]').val(0);

                counter.text(parseInt(count, 10) - 1);

                if (counter.text() == 0) {
                    counter.text("");
                    button.toggleClass('highlight');
                }
            }
        },
        error: function() {
            if (confirm("You have to complete a Captcha in order to ++.")) {
                document.location.href = "/account/turing";
            }
        }
    });
    return false;
}
