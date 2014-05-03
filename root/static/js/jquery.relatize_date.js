// All credit goes to Rick Olson.
(function($) {
  $.fn.relatizeDate = function() {
    return $(this).each(function() {
      var $this = $(this);
      if(!$this.attr("title")) $this.attr( "title", $this.text() );
      $this.text( $.relatizeDate(this) )
    })
  }

  $.relatizeDate = function(element) {
    var str = $(element).attr("title"),
        d = new Date(str), m;
    if(!d || isNaN(d)){
      // match w3cdtf/iso 8601/rfc 3339 (not all browsers will via new Date())
      if( (m = str.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(GMT|UTC|Z)?$/)) ){
        d = m[7] ? // UTC
          new Date(Date.UTC(m[1], m[2]-1, m[3], m[4], m[5], m[6])) :
          new Date(         m[1], m[2]-1, m[3], m[4], m[5], m[6] );
      }
    }
    // if Date is not parseable just return the original string
    return( (!d || isNaN(d)) ? str : $.relatizeDate.timeAgoInWords( d ) );
  };

  // shortcut
  $r = $.relatizeDate

  $.extend($.relatizeDate, {
    shortDays: [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ],
    days: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    shortMonths: [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ],
    months: [ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ],

    /**
     * Given a formatted string, replace the necessary items and return.
     * Example: Time.now().strftime("%B %d, %Y") => February 11, 2008
     * @param {String} format The formatted string used to format the results
     */
    strftime: function(date, format) {
      var day = date.getDay(), month = date.getMonth();
      var hours = date.getHours(), minutes = date.getMinutes();

      var pad = function(num) { 
        var string = num.toString(10);
        return new Array((2 - string.length) + 1).join('0') + string
      };

      return format.replace(/\%([aAbBcdHImMpSwyY])/g, function(match, letter) {
        switch(letter) {
          case 'a': return $r.shortDays[day]; break;
          case 'A': return $r.days[day]; break;
          case 'b': return $r.shortMonths[month]; break;
          case 'B': return $r.months[month]; break;
          case 'c': return date.toString(); break;
          case 'd': return pad(date.getDate()); break;
          case 'H': return pad(hours); break;
          case 'I': return pad((hours + 12) % 12); break;
          case 'm': return pad(month + 1); break;
          case 'M': return pad(minutes); break;
          case 'p': return hours > 12 ? 'PM' : 'AM'; break;
          case 'S': return pad(date.getSeconds()); break;
          case 'w': return day; break;
          case 'y': return pad(date.getFullYear() % 100); break;
          case 'Y': return date.getFullYear().toString(); break;
        }
      })
    },
  
    timeAgoInWords: function(targetDate, includeTime) {
      return $r.distanceOfTimeInWords(targetDate, new Date(), includeTime);
    },
  
    /**
     * Return the distance of time in words between two Date's
     * Example: '5 days ago', 'about an hour ago'
     * @param {Date} fromTime The start date to use in the calculation
     * @param {Date} toTime The end date to use in the calculation
     * @param {Boolean} Include the time in the output
     */
    distanceOfTimeInWords: function(fromTime, toTime, includeTime) {
      var delta = parseInt((toTime.getTime() - fromTime.getTime()) / 1000);
      if (delta < 120) {
          return 'a minute ago';
      } else if (delta < (45*60)) {
          return (parseInt(delta / 60)).toString() + ' minutes ago';
      } else if (delta < (120*60)) {
          return 'an hour ago';
      } else if (delta < (24*60*60)) {
          return (parseInt(delta / 3600)).toString() + ' hours ago';
      } else if (delta < (48*60*60)) {
          return 'one day ago';
      } else {
        var days = (parseInt(delta / 86400)).toString();
        if (days > 5) {
          var fmt  = '%b %d, %Y'
          if (includeTime) fmt += ' %I:%M %p'
          return $r.strftime(fromTime, fmt);
        } else {
          return days + " days ago"
        }
      }
    }
  })
})(jQuery);
