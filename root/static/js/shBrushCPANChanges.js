/**
 * SyntaxHighlighter
 * http://alexgorbatchev.com/SyntaxHighlighter
 *
 * SyntaxHighlighter is donationware. If you are using it, please donate.
 * http://alexgorbatchev.com/SyntaxHighlighter/donate.html
 *
 * @version
 * 3.0.83 (July 02 2010)
 * 
 * @copyright
 * Copyright (C) 2004-2010 Alex Gorbatchev.
 *
 * @license
 * Dual licensed under the MIT and GPL licenses.
 *
 * Brush for CPAN::Changes by Randy Stauner (RWSTAUNER) 2011.
 */
;(function()
{
  // CommonJS
  typeof(require) != 'undefined' ? SyntaxHighlighter = require('shCore').SyntaxHighlighter : null;

  function Brush()
  {
    //var r = SyntaxHighlighter.regexLib;
    
    this.regexList = [
      // these classes/colors are totally arbitrary
      { regex: /^\{\{\$NEXT\}\}$/gm,        css: 'color3' },            // placeholder (oops)
      { regex: /^v?([0-9._]+)(-TRIAL)?\s+(.+)/gm,    css: 'constants' },             // version/date
      { regex: /^\s+\[.+?\]/gm,             css: 'value' },         // group
      { regex: /^\s+[-*]/gm,                css: 'functions' },         // item marker
      { regex: /^[^v0-9].+\n(?=\nv?[0-9_.])/g,  css: 'preprocessor' }   // preamble
    ];
  };

  Brush.prototype = new SyntaxHighlighter.Highlighter();
  Brush.aliases = ['cpanchanges'];

  SyntaxHighlighter.brushes.CPANChanges = Brush;

  // CommonJS
  typeof(exports) != 'undefined' ? exports.Brush = Brush : null;
})();
