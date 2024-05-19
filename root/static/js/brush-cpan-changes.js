const BrushBase = require('brush-base');
const regexLib = require('syntaxhighlighter-regex').commonRegExp;

function Brush() {
    this.regexList = [
        // these classes/colors are totally arbitrary
        {
            regex: /^\{\{\$NEXT\}\}$/gm,
            css: 'color3'
        }, // placeholder (oops)
        {
            regex: /^v?([0-9._]+)(-TRIAL)?([ \t]+.+)?/gm,
            css: 'constants'
        }, // version/date
        {
            regex: /^\s+\[.+?\]/gm,
            css: 'value'
        }, // group
        {
            regex: /^\s+[-*]/gm,
            css: 'functions'
        }, // item marker
        {
            regex: /^[^v0-9].+\n(?=\nv?[0-9_.])/g,
            css: 'preprocessor'
        } // preamble
    ];
};

Brush.prototype = new BrushBase();
Brush.aliases = ['cpanchanges'];
module.exports = Brush;
