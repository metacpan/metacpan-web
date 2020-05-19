/* ========================================================
 * bootstrap-slidepanel.js v2.3.0
 * http://twitter.github.com/bootstrap/javascript.html#slide-panel
 * ========================================================
 * Author: Moritz Onken <onken@netcubed.de>
 */


!function ($) {

  "use strict"; // jshint ;_;


 /* SLIDEPANEL CLASS DEFINITION
  * ==================== */

  var SlidePanel = function (element) {
    this.element = $(element)
  }

  SlidePanel.prototype = {

    constructor: SlidePanel

  , toggle: function () {
      var $this = this.element
        , selector = $this.attr('data-target')
        , width = $this.attr('data-slidepanel-width')
        , $target
        , e

      e = $.Event('toggle')

      $this.trigger(e)

      if (e.isDefaultPrevented()) return

      $target = $(selector)
  	  
  	  if(!width) {
  	  	width = $target.outerWidth()
  	  	$this.attr('data-slidepanel-width', width)
  	  	$target.css('left', -width).css('visibility', 'visible');
  	  }

  	  if($target.hasClass('slidepanel-visible'))
  	  	this.hide()
  	  else
  	  	this.show()
    }

  , show: function ( $target ) {
      var $this = this.element
        , selector = $this.attr('data-target')
        , width = $this.attr('data-slidepanel-width')
        , e
      
      if(!$target) $target = $(selector)

      $target.css('transform', 'translateX(' + width + 'px)').addClass('slidepanel-visible');
      $this.find("i").each(function(){
        $(this).removeClass('fa-bars').addClass('fa-times');
      });
    }

   , hide: function ( $target ) {
      var $this = this.element
        , selector = $this.attr('data-target')
        , width = $this.attr('data-slidepanel-width')
        , e
      
      if(!$target) $target = $(selector)
      $this.find("i").each(function(){
        $(this).removeClass('fa-times').addClass('fa-bars');
      });
      $target.css('transform', 'translateX(0px)').removeClass('slidepanel-visible');
    }
  }


 /* SLIDEPANEL PLUGIN DEFINITION
  * ===================== */

  var old = $.fn.slidepanel

  $.fn.slidepanel = function ( option ) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('slidepanel')
      if (!data) $this.data('slidepanel', (data = new SlidePanel(this)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.slidepanel.Constructor = SlidePanel


 /* SLIDEPANEL NO CONFLICT
  * =============== */

  $.fn.slidepanel.noConflict = function () {
    $.fn.slidepanel = old
    return this
  }


 /* SLIDEPANEL DATA-API
  * ============ */

  $(document).on('click.slidepanel.data-api', '[data-toggle="slidepanel"]', function (e) {
  	e.preventDefault()
    $(this).slidepanel('toggle')
  })

}(window.jQuery);
