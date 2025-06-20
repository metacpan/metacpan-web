'use strict';

const relatizeDate = require('./relatize_date.js');
const storage = require('./storage.js');
const Mousetrap = require('mousetrap');
const {
    formatTOC,
    createAnchors
} = require('./document-ui.mjs');

const jQuery = require('jquery');
require('bootstrap/js/dropdown.js');
require('bootstrap/js/modal.js');
require('bootstrap/js/tooltip.js');


async function processUserData() {
    let user_data;
    try {
        user_data = await fetch('/account/login_status').then(res => res.json());
    }
    catch {
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

}

function set_page_size(selector, storage_name) {
    for (const el of document.querySelectorAll(selector)) {
        const result = el.href.match(/[&;?]size=(\d+)(?:$|[&;])/);
        if (result && result[1]) {
            const size = result[1];
            el.addEventListener('click', () => {
                storage.setItem(storage_name, size);
            });
            return;
        }
        const storage_size = storage.getItem(storage_name);
        if (storage_size) {
            if (el.href.match(/\?/)) {
                el.href += '&size=' + storage_size;
            }
            else {
                el.href += '?size=' + storage_size;
            }
        }
    }
}

// poor man's RFC-6570 formatter
function format_string(input_string, replacements) {
    const output_string = input_string.replace(
        /\{(\/?)(\w+)\}/g,
        (x, slash, placeholder) =>
        Object.hasOwn(replacements, placeholder) ?
        slash + replacements[placeholder] : ''
    );
    return output_string;
}

// User customisations
processUserData();

jQuery(".ttip").tooltip(); // bootstrap

for (const el of document.querySelectorAll('.keyboard-shortcuts')) {
    el.addEventListener('click', e => {
        e.preventDefault();
        jQuery('#metacpan_keyboard-shortcuts').modal(); // bootstrap
    });
}

// Global keyboard shortcuts
Mousetrap.bind('?', function() {
    jQuery('#metacpan_keyboard-shortcuts').modal(); // bootstrap
});
Mousetrap.bind('s', function(e) {
    e.preventDefault();
    document.querySelector('#metacpan_search-input').focus();
});

// install a default handler for 'g s' for non pod pages
Mousetrap.bind('g s', () => {});

for (const el of document.querySelectorAll('a[data-keyboard-shortcut]')) {
    Mousetrap.bind(el.dataset.keyboardShortcut, () => {
        window.location = el.href;
    });
}

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

for (const el of document.querySelectorAll('.ellipsis')) {
    const text = el.textContent;

    // try to find a reasonable place to cut to allow mid-abbreviation.
    // we want to cut "near" the middle, but prefer on a boundary.
    const initial_cut = Math.floor(text.length / 5 * 3);
    let start_text = text.substr(0, initial_cut);
    let end_text = text.substr(initial_cut);
    const res = start_text.match(/^(.*[- :])(.*?)$/);
    if (res && res[1].length > text.length / 4) {
        start_text = res[1];
        end_text = res[2] + end_text;
    }

    const start = document.createElement('span');
    start.append(start_text);
    const end = document.createElement('span');
    end.append(end_text);

    el.replaceChildren();

    el.append(end);
    start.style.maxWidth = 'calc(100% - ' + end.clientWidth + 'px)';
    el.prepend(start);
}

createAnchors(document.querySelectorAll('.anchors'));

jQuery('.dropdown-toggle').dropdown(); // bootstrap

const toc = document.querySelector(".content .toc")
if (toc) {
    formatTOC(toc);
}

for (const link of document.querySelectorAll('a[href*="/search?"]')) {
    link.addEventListener('click', () => {
        const result = link.href.match(/size=(\d+)/);
        if (result && result[1]) {
            storage.setItem('search_size', result[1]);
        }
    });
}

const size = storage.getItem('search_size');
if (size) {
    document.querySelector('#metacpan_search-size').value = size;
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

for (const sel of document.querySelectorAll('.select-navigator')) {
    sel.addEventListener('change', () => {
        document.location.href = sel.value;
        sel.selectedIndex = 0;
    });
}

const contribs = document.querySelector('#metacpan_contributors');
if (contribs) {
    const contrib_button = document.querySelector('.contributors-show-button');
    contrib_button.addEventListener('click', e => {
        e.preventDefault();
        contrib_button.style.display = 'none';
        contribs.classList.remove('slide-out-hidden');
        contribs.classList.add('slide-down');
    });
}
