'use strict';
import jQuery from 'jquery';

import 'devbridge-autocomplete';

// Autocomplete issues:
// #345/#396 Up/down keys should put selected value in text box for further editing.
// #441 Allow more specific queries to send ("Ty", "Type::").
// #744/#993 Don't select things if the mouse pointer happens to be over the dropdown when it appears.
// Please don't steal ctrl-pg up/down.
const search_input = document.querySelector('#metacpan_search-input');
const ac_width = search_input.offsetWidth;

jQuery(search_input).autocomplete({
    serviceUrl:                '/search/autocomplete',
    // Wait for more typing rather than firing at every keystroke.
    deferRequestBy:            150,
    // If the autocomplete fires with a single colon ("type:") it will get no results
    // and anything else typed after that will never trigger another query.
    // Set 'preventBadQueries:false' to keep trying.
    preventBadQueries:         false,
    dataType:                  'json',
    lookupLitmit:              20,
    paramName:                 'q',
    autoSelectFirst:           false,
    // This simply caches the results of a previous search by url (so no reason not to).
    noCache:                   false,
    triggerSelectOnValidInput: false,
    maxHeight:                 180,
    width:                     ac_width,
    onSelect:                  function (suggestion) {
        if (suggestion.data.type == 'module') {
            document.location.href = '/pod/' + suggestion.data.module;
        }
        else if (suggestion.data.type == 'author') {
            document.location.href = '/author/' + suggestion.data.id;
        }
    },
});
const ac = jQuery(search_input).autocomplete();
const formatResult = ac.options.formatResult;
ac.options.formatResult = function (suggestion, currentValue) {
    const out = formatResult(suggestion, currentValue);
    if (suggestion.data.type == 'author') {
        return '<span class="suggest-author-label">Author:</span> ' + out;
    }
    return out;
};

// Disable the built-in hover events to work around the issue that
// if the mouse pointer is over the box before it appears the event may fire erroneously.
// Besides, does anybody really expect an item to be selected just by
// hovering over it?  Seems unintuitive to me.  I expect anyone would either
// click or hit a key to actually pick an item, and who's going to hover to
// the item they want and then instead of just clicking hit tab/enter?
jQuery('.autocomplete-suggestions').off('mouseover.autocomplete');
jQuery('.autocomplete-suggestions').off('mouseout.autocomplete');
