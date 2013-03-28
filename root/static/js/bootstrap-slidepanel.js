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

  	  $this.css('transform', 'translateX(' + width + 'px)')
      $target.css('transform', 'translateX(' + width + 'px)').addClass('slidepanel-visible');
    }

   , hide: function ( $target ) {
      var $this = this.element
        , selector = $this.attr('data-target')
        , width = $this.attr('data-slidepanel-width')
        , e
      
      if(!$target) $target = $(selector)

      $target.css('transform', 'translateX(0px)').removeClass('slidepanel-visible');
  	  $this.css('transform', 'translateX(0px)')
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

/*

<style>

body {
  overflow-x: hidden;
}

.slidepanel {
  position: fixed;
  top: 0px;
  visibility: hidden;
  width: 200px;
  -webkit-transition: -webkit-transform .4s;
  z-index: 1500;
  height: 100%;
  overflow: auto;
  white-space:nowrap;
}

.slidepanel-visible {
}

.btn.btn-slidepanel {
  position: relative;
  display: block;
  float: left;
  -webkit-transition: left .4s;
}

.navbar-inner .container {
  white-space:nowrap;
}


</style>

 */