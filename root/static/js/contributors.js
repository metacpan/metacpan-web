$(function(){
    function updateContrib ( li, data ){
        if (!data.name) {
            return;
        }
        var anchor = li.find('a.cpan-author');
        if (anchor.length == 0) {
            li.contents().wrap('<a class="cpan-author"></a>');
            anchor = li.find('a.cpan-author');
        }

        li.attr( 'data-cpan-author', data.pauseid );
        anchor.attr( 'href', '/author/' + data.pauseid );
        anchor.text( data.name );

        var gravatar = data.gravatar_url;
        if (gravatar) {
            gravatar = gravatar.replace(
                "^https?://([a-z0-9.-]+\.)?gravatar\.com/",
                "https://secure.gravatar.com/",
                "i"
            ).replace(
                /s=\d+/,
                's=20'
            );

            var img = $('<img />')
                .attr( 'width', 20 )
                .attr( 'height', 20 );
            anchor.prepend( img );
            img.addClass( 'gravatar' );
            img.attr( 'src', gravatar )
        }
    }


    $('#contributors .contributor').each(function(){
        var li = $(this);
        var author;
        var email;
        if( author = li.attr('data-cpan-author')) {
            $.getJSON( "https://api.metacpan.org/author/" + author, function(data) {
                updateContrib(li, data);
            });
        }
        else if ( email = li.attr('data-contrib-email') ) {
            var filter = $.map(email.split(/\s+/), function(em){
              return {
                "term": {
                  "email" : em
                }
              };
            });
            var query = {
              "query" : {
                "match_all" : {}
              },
              "filter": {
                "or" : filter
              },
              "fields" : [
                "name",
                "email",
                "pauseid",
                "gravatar_url"
              ],
              "size": 1
            };
            $.ajax({
                type: "POST",
                url: "https://api.metacpan.org/author/",
                data: JSON.stringify(query),
                dataType: "json",
                contentType: "application/x-www-form-urlencoded; charset=UTF-8", // a lie to bypass cors
                processData: false,
                success: function (data) {
                    if (data.hits.total == 1) {
                        updateContrib(li, data.hits.hits[0].fields);
                    }
                }
            });
        }
    });
});
