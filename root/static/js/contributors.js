$(function(){
    function gravatar_fixup ( av, size ) {
        av = av.replace(
            /^https?:\/\/([a-z0-9.-]+\.)?gravatar\.com\//i,
            "https://secure.gravatar.com/"
        );
        av = av.replace(
            /([;&?])s=\d+/,
            '$1s=20'
        );
        av = av.replace(
            /([;&?]d=)([^;&?]+)/,
            function (match, param, fallback) {
                var url = decodeURIComponent(fallback);
                url = gravatar_fixup(url);
                return(param + encodeURIComponent(url));
            }
        );
        return av;
    }
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
            gravatar = gravatar_fixup(gravatar);

            var img = $('<img />')
                .attr( 'width', 20 )
                .attr( 'height', 20 );
            anchor.prepend( img );
            img.addClass( 'gravatar' );
            img.attr( 'src', gravatar )
        }
    }


    var filter = [];
    var by_author = {};
    var by_email = {};
    $('#contributors .contributor').each(function(){
        var li = $(this);
        var author;
        var email;
        if( author = li.attr('data-cpan-author')) {
            filter.push({ "term" : { "pauseid" : author } });
            by_author[author] = li;
        }
        else if ( email = li.attr('data-contrib-email') ) {
            $.each(email.split(/\s+/), function(i, em){
                filter.push({ "term" : { "email" : em } });
                by_email[em] = li;
            });
        }
    });

    var query = {
        "query" : {
            "match_all" : {}
        },
        "filter": {
            "or" : filter
        },
        "_source" : [
            "name",
            "email",
            "pauseid",
            "gravatar_url"
        ]
    };

    $.ajax({
        type: "POST",
        url: "https://fastapi.metacpan.org/author/",
        data: JSON.stringify(query),
        dataType: "json",
        contentType: "application/x-www-form-urlencoded; charset=UTF-8", // a lie to bypass cors
        processData: false,
        success: function (data) {
            $.each(data.hits.hits, function(i, contrib){
                var fields = contrib._source;
                if (fields.email) {
                    $.each(fields.email, function(i, email){
                        if (by_email[email]) {
                            updateContrib(by_email[email], fields);
                        }
                    });
                }
                if (fields.pauseid && by_author[fields.pauseid]) {
                    updateContrib(by_author[fields.pauseid], fields);
                }
            });
        }
    });
});
