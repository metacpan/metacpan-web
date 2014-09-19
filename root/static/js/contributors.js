$(function(){
    $('a.cpan_author').each(function(){
        var $anchor = $(this);
        var author = $anchor.attr('data-cpan-author');
        if( typeof author == 'undefined' ) {
            return;
        }

        $.getJSON( "https://api.metacpan.org/author/" + author, function( data ){
            if ( typeof data.name == 'undefined' ) {
                return;
            }
            $anchor.attr( 'data-cpan-author', data.pauseid );
            $anchor.attr( 'href', '/author/' + data.pauseid );
            $anchor.text( data.name );

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

                var $img = $anchor.find('img.gravatar');
                if (!$img.length) {
                    $img = $('<img />')
                        .attr( 'width', 20 )
                        .attr( 'height', 20 );
                    $anchor.prepend( $img );
                }
                $img.addClass( 'gravatar' );
                $img.attr( 'src', gravatar )
            }
        });
    });
});
