/* jshint white: true, lastsemic: true */

const relatizeDate = require('./relatize_date.js');
const storage = require('./storage.js');
const Mousetrap = require('mousetrap');
const {
    formatTOC,
    createAnchors
} = require('./document-ui.mjs');

// Store global data in this object
var MetaCPAN = {};

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


function setFavTitle(button) {
    button.setAttribute('title', button.classList.contains('active') ? 'Remove from favorites' : 'Add to favorites');
}

async function processUserData() {
    let user_data;
    try {
        user_data = await fetch('/account/login_status').then(res => res.json());
    } catch (e) {
        document.body.classList.remove('logged-in');
        document.body.classList.add('logged-out');
        return;
    }
    if (!user_data.logged_in) {
        document.body.classList.remove('logged-in');
        document.body.classList.add('logged-out');
        return;
    }

    document.body.classList.add('logged-in');
    document.body.classList.remove('logged-out');

    if (user_data.avatar) {
        const base_av = format_string(user_data.avatar, {
            size: 35
        });
        const double_av = format_string(user_data.avatar, {
            size: 70
        });

        const avatar = document.createElement('img');
        avatar.classList.add('logged-in-avatar');
        avatar.src = base_av;
        avatar.srcset = `${base_av}, ${double_av} 2x`;
        avatar.crossorigin = 'anonymous';
        document.querySelector('.logged-in-icon').replaceWith(avatar);
    }

    // process users current favs
    for (const fav of user_data.faves) {
        const distribution = fav.distribution;

        // On the page... make it deltable and styled as 'active'
        const fav_display = document.querySelector(`#${distribution}-fav`);

        if (fav_display) {
            fav_display.querySelector('input[name="remove"]').value = 1;
            var button = fav_display.querySelector('button');
            button.classList.add('active');
            setFavTitle(button);
        }
    }
}

$(document).ready(function() {

    // User customisations
    processUserData();

    $(".ttip").tooltip();

    $('.keyboard-shortcuts').each(function() {
        $(this).click(function(event) {
            $('#metacpan_keyboard-shortcuts').modal();
            event.preventDefault();
        })
    });

    // Global keyboard shortcuts
    Mousetrap.bind('?', function() {
        $('#metacpan_keyboard-shortcuts').modal();
    });
    Mousetrap.bind('s', function(e) {
        $('#metacpan_search-input').focus();
        e.preventDefault();
    });

    // install a default handler for 'g s' for non pod pages
    Mousetrap.bind('g s', function(e) {});

    $('a[data-keyboard-shortcut]').each(function(index, element) {
        Mousetrap.bind($(element).data('keyboard-shortcut'), function() {
            window.location = $(element).attr('href');
        });
    });

    for (const logout of document.querySelectorAll('.logout-button')) {
        logout.addEventListener('click', e => {
            e.preventDefault();
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/account/logout';
            document.body.appendChild(form);
            form.submit();
        });
    }

    relatizeDate(document.querySelectorAll('.relatize'));

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

    createAnchors(document.querySelectorAll('.anchors'));

    for (const favButton of document.querySelectorAll('.breadcrumbs .favorite')) {
        setFavTitle(favButton);
    }

    $('.dropdown-toggle').dropdown();

    function format_toc(toc) {
        'use strict';
        if (storage.getItem('hideTOC') == 1) {
            toc.classList.add("hide-toc");
        }

        const toc_header = toc.querySelector('.toc-header');
        const toc_body = toc.querySelector('ul');

        toc_header.insertAdjacentHTML('beforeend',
            ' [ <button class="btn-link toggle-toc"><span class="toggle-show">show</span><span class="toggle-hide">hide</span></button> ]'
        );
        toc_header.querySelector('.toggle-toc').addEventListener('click', e => {
            e.preventDefault();
            const currentVisible = !toc.classList.contains('hide-toc');
            storage.setItem('hideTOC', currentVisible ? 1 : 0);

            const fullHeight = toc_body.scrollHeight;

            if (currentVisible) {
                const trans = toc_body.style.transition;
                toc_body.style.transition = '';

                requestAnimationFrame(() => {
                    toc_body.style.height = fullHeight + 'px';
                    toc_body.style.transition = trans;
                    toc.classList.toggle('hide-toc');

                    requestAnimationFrame(() => {
                        toc_body.style.height = null;
                    });
                });
            } else {
                const finish = e => {
                    toc_body.removeEventListener('transitionend', finish);
                    toc_body.style.height = null;
                };

                toc_body.addEventListener('transitionend', finish);
                toc_body.style.height = fullHeight + 'px';
                toc.classList.toggle('hide-toc');
            }
        });
    }

    const toc = document.querySelector(".content .toc")
    if (toc) {
        formatTOC(toc);
    }

    $('a[href*="/search?"]').on('click', function() {
        var url = $(this).attr('href');
        var result = /size=(\d+)/.exec(url);
        if (result && result[1]) {
            storage.setItem('search_size', result[1]);
        }
    });
    var size = storage.getItem('search_size');
    if (size) {
        $('#metacpan_search-size').val(size);
    }

    // TODO use a more specific locator for /author/PAUSID/release ?
    set_page_size('a[href*="/releases"]', 'releases_page_size');
    set_page_size('a[href*="/recent"]', 'recent_page_size');
    set_page_size('a[href*="/requires"]', 'requires_page_size');

    const changes = document.querySelector('#metacpan_last-changes');
    if (changes) {
        const changes_content = changes.querySelector('.changes-content');
        const changes_toggle = changes.querySelector(".changes-toggle");
        changes.classList.add('collapsable', 'collapsed');

        const content_height = Math.round(changes_content.scrollHeight);
        const toggle_style = window.getComputedStyle(changes_toggle);

        const potential_size = Math.round(
            changes_content.offsetHeight +
            changes_toggle.offsetHeight
        );

        if (content_height <= potential_size) {
            changes.classList.remove('collapsable', 'collapsed');
        }
        changes_toggle.addEventListener('click', e => {
            e.preventDefault();
            changes.classList.toggle('collapsed');
        });
    }

    for (const favForm of document.querySelectorAll('form[action="/account/favorite/add"]')) {
        favForm.addEventListener('submit', async e => {
            e.preventDefault();
            const formData = new FormData(favForm);
            let response;
            try {
                response = await fetch(favForm.action, {
                    method: favForm.method,
                    headers: {
                        'Accepts': 'application/json',
                    },
                    body: formData,
                });
            } catch (e) {
                if (confirm("You have to complete a Captcha in order to ++.")) {
                    document.location.href = "/account/turing";
                }
            }

            const button = favForm.querySelector('button');
            button.classList.toggle('active');
            setFavTitle(button);
            const counter = button.querySelector('span');
            const count = counter.innerText;
            if (button.classList.contains('active')) {
                counter.innerText = count ? parseInt(count, 10) + 1 : 1;
                // now added let users remove
                favForm.querySelector('input[name="remove"]').value = 1;
                if (!count)
                    button.classList.toggle('highlight');
            } else {
                // can't delete what's already deleted
                favForm.querySelector('input[name="remove"]').value = 0;

                counter.textContent = parseInt(count, 10) - 1;

                if (counter.textContent == 0) {
                    counter.textContent = '';
                    button.classList.toggle('highlight');
                }
            }
        });
    }

    for (const favButton of document.querySelectorAll('.fav-not-logged-in')) {
        favButton.addEventListener('click', e => {
            e.preventDefault();
            alert('Please sign in to add favorites');
        });
    }

    for (const sel of document.querySelectorAll('.select-navigator')) {
        sel.addEventListener('change', () => {
            document.location.href = sel.value;
            sel.selectedIndex = 0;
        });
    }
});

function set_page_size(selector, storage_name) {
    $(selector).each(function() {
        var url = this.href;
        var result = /[&;?]size=(\d+)(?:$|[&;])/.exec(url);
        var size;
        if (result && result[1]) {
            size = result[1];
            $(this).click(function() {
                storage.setItem(storage_name, size);
                return true;
            });
        } else if (size = storage.getItem(storage_name)) {
            if (/\?/.exec(url)) {
                this.href += '&size=' + size;
            } else {
                this.href += '?size=' + size;
            }
        }
        return true;
    });
}

// poor man's RFC-6570 formatter
function format_string(input_string, replacements) {
    const output_string = input_string.replace(
        /\{(\/?)(\w+)\}/g,
        (x, slash, placeholder) =>
        replacements.hasOwnProperty(placeholder) ?
        slash + replacements[placeholder] : ''
    );
    return output_string;
}
