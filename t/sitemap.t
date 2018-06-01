use strict;
use warnings;

use Test::More;

use Compress::Zlib;
use HTTP::Request::Common;
use LWP::UserAgent;

check_sitemap( 'https://metacpan.org/sitemap-releases.xml.gz' );
check_sitemap( 'https://metacpan.org/sitemap-releases.xml.gz' )

done_testing();

sub check_sitemap {
    my ( $url ) = @_;

    if( my $sitemap = download( $url ) ) {
        while( $sitemap =~ /\<loc\>(.+?)\<\/loc\>/gxo ) {
            my $url = $1;

            check( $url );
        }
    }

    return;
}

sub download {
    my ( $url ) = @_;

    my $response = ua() -> request( GET $url );

    return $response -> is_success()
         ? ( Compress::Zlib::memGunzip( \( $response -> content() ) ) or die "Cannot uncompress: $gzerrno\n" )
         : undef;
}

sub check {
    my ( $url ) = @_;

    my $response = ua() -> request( HEAD $url );

    ok( $response -> is_success(), sprintf "%s %s", $response -> status_line(), $url );

    return;
}

{
    my $ua;
    sub ua {

        if( !$ua ) {
            $ua = LWP::UserAgent -> new();
        }

        return $ua;
    }
}