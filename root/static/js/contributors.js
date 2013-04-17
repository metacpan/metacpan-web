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
            // TODO make this an :before pseudo-class
            var gravatar = data.gravatar_url;
            gravatar = gravatar.replace( 
                "^http://(www\.)?gravatar.com/",
                "https://secure.gravatar.com/"
            ).replace(
                /s=\d+/,
                's=20'
            );
            var $img = $('<img />').attr( 'src', gravatar )
                .attr( 'width', 20 )
                .attr( 'height', 20 );
            $anchor.text( data.name );
            $anchor.parent().addClass('gravatar');
            $anchor.before( $img );
        });
    });
});
