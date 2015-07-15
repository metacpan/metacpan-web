/* jshint white: true, lastsemic: true */

// Store global data in this object
var MetaCPAN = {};
// Collect favs we need to check after dom ready
MetaCPAN.favs_to_check = {};

// provide localStorage shim to work around https://bugzilla.mozilla.org/show_bug.cgi?id=748620
try {
    MetaCPAN.storage = window.localStorage;
} catch (e) {
    MetaCPAN.storage = {
        getItem: function(k) {
            return this["_" + k];
        },
        setItem: function(k, v) {
            return this["_" + k] = v;
        },
    };
}

document.cookie = "hideTOC=; expires=" + (new Date(0)).toGMTString() + "; path=/";

$.fn.textWidth = function() {
    var html_org = $(this).html();
    var html_calc = '<span>' + html_org + '</span>';
    $(this).html(html_calc);
    var width = $(this).find('span:first').width();
    $(this).html(html_org);
    return width;
};

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

$(document).ready(function() {

    // User customisations
    processUserData();

    $(".ttip").tooltip();

    $('#signin-button').mouseenter(function() {
        $('#signin').show()
    });
    $('#signin').mouseleave(function() {
        $('#signin').hide()
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

        var sortid = (
            MetaCPAN.storage.getItem("tablesorter:" + table.attr('id')) ||
            table.attr('data-default-sort') || '0,0');
        sortid = JSON.parse("[" + sortid + "]");

        var cfg = {
            sortList: [sortid],
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

        table.find('thead th').each(function(i, el) {
            if ($(el).hasClass('no-sort')) {
                cfg.headers[i] = {
                    sorter: false
                };
            }
        });

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
    var ac_width = search_input.outerWidth();
    if (search_input.hasClass('top-input-form')) {
        ac_width += search_input.parents("form.search-form").first().find('.search-btn').first().outerWidth();
    }
    search_input.bind('modules_autocomplete', function() {
        $(this).autocomplete({
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
            transformResult: function(data) {
                var result = $.map(data, function(row) {
                    return {
                        data: row.documentation,
                        value: row.documentation
                    };
                });
                var uniq = {};
                result = $.grep(result, function(row) {
                    uniq[row.value] = typeof(uniq[row.value]) == 'undefined' ? 0 : uniq[row.value];
                    return uniq[row.value]++ < 1;
                });
                return {
                    suggestions: result
                };
            },
            onSelect: function(suggestion) {
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
    });

    search_input.bind('authors_autocomplete', function() {
        $(this).constructorAutocomplete({
            key: 'bQssESEa8XUBKzSUjarO',
            directResults: true,
            maxHeight: 400,
            transformResult: function(response) {
                if (response['sections'] && response['sections']['url']) {
                    response['sections']['url'].forEach(function(dataset) {
                        if (dataset.value) {
                            dataset.value = dataset.value.replace(/^[^:]+: /, "");
                        }
                    });
                }
                return response;
            }
        });

        // Disable the built-in hover events (see comment above)
        $('.autocomplete-suggestions').off('mouseover.autocomplete');
        $('.autocomplete-suggestions').off('mouseout.autocomplete');
    });
    search_input.trigger('modules_autocomplete');
    $.getScript("//cnstrc.com/js/ac.js", function() {
        if ($('input[name=search_type]:checked').val() == "authors") {
            search_input.trigger('authors_autocomplete');
        }
    });

    $("input[name=search_type]").click(function() {
        if ($(this).val() == "authors") {
            if (typeof $("#search-input").autocomplete === "function") {
                $("#search-input").autocomplete("dispose");
            }
            search_input.trigger('authors_autocomplete');
        } else {
            if (typeof $("#search-input").constructorAutocomplete === "function") {
                $("#search-input").constructorAutocomplete("dispose");
            }
            search_input.trigger('modules_autocomplete');
        }
    });

    $('#search-input.autofocus').focus();

    var items = $('.ellipsis');
    for (var i = 0; i < items.length; i++) {
        var element = $(items[i]);
        var boxWidth = element.width();
        var textWidth = element.textWidth();
        if (textWidth <= boxWidth) continue;
        var text = element.text();
        var textLength = text.length;
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

    $('.anchors').find('h1,h2,h3,h4,h5,h6,dt').each(function() {
        if (this.id) {
            $(this).prepend('<a href="#' + this.id + '" class="anchor"><span class="fa fa-bookmark black"></span></a>');
        }
    });

    var module_source_href = $('#source-link').attr('href');
    if (module_source_href) {
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
    $('#pod-errors > p:first-child').click(function() {
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

    if ($(".inline").find("button").hasClass("active")) {
        $(".favorite").attr("title", "Remove from favorite");
    } else {
        $(".favorite").attr("title", "Add to favorite");
    }

    $('.dropdown-toggle').dropdown();

    var index = $("#index");
    if (index) {
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
        $('#size').val(size);
    }

    // The install a CPAN Module boiler plate
    $('#install_dialog').on('click', function() {
        $('#install_module').modal('show');
    });

    // TODO use a more specific locator for /author/PAUSID/release ?
    set_page_size('a[href*="/releases"]', 'releases_page_size');
    set_page_size('a[href*="/recent"]', 'recent_page_size');
    set_page_size('a[href*="/requires"]', 'requires_page_size');

});

function set_page_size(selector, storage_name) {
    $(selector).on('click', function() {
        var url = $(this).attr('href');
        var result = /size=(\d+)/.exec(url);
        if (result && result[1]) {
            var page_size = result[1];
            MetaCPAN.storage.setItem(storage_name, page_size);
            return true;
        } else {
            page_size = MetaCPAN.storage.getItem(storage_name);
            if (page_size) {
                if (/\?/.exec(url)) {
                    document.location.href = url + '&size=' + page_size;
                } else {
                    document.location.href = url + '?size=' + page_size;
                }
                return false;
            };
        }
    });
}


function searchForNearest() {
    $("#busy").css({
        visibility: 'visible'
    });
    navigator.geolocation.getCurrentPosition(function(pos) {
            var query = $.getUrlVar('q');
            if (!query) {
                query = '';
            }
            query = query.replace(/(^|\s+)loc:\S+|$/, '');
            query = query + ' loc:' + pos.coords.latitude + ',' + pos.coords.longitude;
            query = query.replace(/(^|\s)\s+/g, '$1');
            document.location.href = '/mirrors?q=' + encodeURIComponent(query);
        },
        function() {
            $("#busy").css({
                visibility: 'hidden'
            });
        }, {
            maximumAge: 600000
        });
}

function logInPAUSE(a) {
    if (!a.href.match(/pause/))
        return true;
    var id = prompt('Please enter your PAUSE ID:');
    if (id) document.location.href = a.href + '&id=' + id;
    return false;
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
        if (MetaCPAN.favs_to_check[distribution]) {
            $('#' + distribution + '-fav input[name="remove"]').val(1);
            $('#' + distribution + '-fav button').addClass('active');
        }

    });

}

function getFavDataFromServer() {
    $.ajax({
        type: 'GET',
        url: '/account/favorite/list_as_json',
        success: function(databack) {
            showUserData(databack);
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
