import jQuery from 'jquery';
import storage from './storage.js';

import 'tablesorter';

for (const table of document.querySelectorAll('table.tablesorter')) {
    const cfg = {
        textExtraction: function(node) {
            const sort = node.getAttribute("sort");
            if (!sort) return node.textContent;
            if (node.classList.contains("date")) {
                return (new Date(sort)).getTime();
            }
            else {
                return sort;
            }
        },
        headers: {}
    };

    const sortable = [];
    for (const [i, el] of [...table.querySelectorAll(':scope thead th')].entries()) {
        const header = {};
        if (el.classList.contains('no-sort')) {
            header.sorter = false;
        }
        else {
            sortable.push(i);
        }
        cfg.headers[i] = header;
    }

    let sortid;
    if (table.id) {
        const storageid = table.id.replace(/^metacpan_/, '');
        sortid = storage.getItem("tablesorter:" + storageid);
    }
    if (!sortid && table.dataset.defaultSort) {
        sortid = table.dataset.defaultSort;
    }
    if (!sortid) {
        const match = window.location.search.match(/[?&]sort=\[\[([0-9,]+)\]\]/);
        if (match) {
            sortid = decodeURIComponent(match[1]);
        }
        else {
            sortid = '0,0';
        }
    }
    try {
        sortid = JSON.parse('[' + sortid + ']');
    }
    catch (e) {
        sortid = [0, 0];
    }

    let sortCol;
    const sortHeader = cfg.headers[sortid[0]];
    if (typeof sortHeader === 'undefined') {
        sortCol = [sortable[0], 0];
    }
    else if (sortHeader.sorter == false) {
        sortCol = [sortable[0], 0];
    }
    else {
        sortCol = sortid;
    }
    cfg.sortList = [sortCol];

    jQuery(table).tablesorter(cfg);
}

for (const header of document.querySelectorAll('.tablesorter.remote th.header')) {
    jQuery(header).unbind('click');
    header.addEventListener('click', () => {
        const loc = new URL(document.location);
        loc.searchParams.set('sort',
            JSON.stringify([
                [header.column, header.count++ % 2]
            ]));
        window.location.assign(loc);
    });
}

for (const header of document.querySelectorAll('.tablesorter th.header')) {
    const tableid = header.closest('table').id;
    const storageid = tableid.replace(/^metacpan_/, '');
    header.addEventListener('click', () => {
        setTimeout(function() {
            var sortParam = (new URL(document.location)).searchParams.get('sort');
            if (sortParam != null) {
                sortParam = sortParam.slice(2, sortParam.length - 2);
                storage.setItem("tablesorter:" + storageid, sortParam);
            }
        }, 1000);
    });
}
