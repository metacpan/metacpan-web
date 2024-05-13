import jQuery from 'jquery';
import { SyntaxHighlighter } from './shCore.js';

window.SyntaxHighlighter = SyntaxHighlighter;
window.$ = jQuery;
window.jQuery = jQuery;

export {
    jQuery as default,
    jQuery,
    jQuery as $,
};
