package MetaCPAN::Web::View::HTML;

use Moose;
extends 'Catalyst::View::TT::Alloy';

use Digest::SHA;
use List::Util       ();
use Cpanel::JSON::XS ();
use Gravatar::URL;
use Regexp::Common qw(time);
use Template::Plugin::DateTime;
use Template::Plugin::JSON;
use Template::Plugin::Markdown;
use Template::Plugin::Number::Format;
use Template::Plugin::Page;
use Text::Pluralize ();
use URI;
use URI::QueryParam;

sub parse_datetime {
    my $date = shift;
    if ( $date =~ /^\d+$/ ) {
        my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($date);
        return {
            year   => $year + 1900,
            month  => $mon + 1,
            day    => $mday,
            hour   => $hour,
            minute => $min,
            second => $sec,
        };
    }
    elsif ( $date =~ /$RE{time}{iso}{-keep}/ ) {
        return {
            year   => $2,
            month  => $3,
            day    => $4,
            hour   => $5,
            minute => $6,
            second => $7,
        };
    }
    else {
        return;
    }
}

my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @DoW = qw(Mon Tue Wed Thu Fri Sat Sun);

sub format_datetime {
    my $date = shift;
    my $dt   = parse_datetime($date);
    return sprintf(
        '%02d %s %04d %02d:%02d:%02d GMT',
        $dt->{day},
        $MoY[ $dt->{month} - 1 ],
        @$dt{qw(year hour minute second)}
    );
}

# format just the date consistent with W3CDTF / ISO 8601 / RFC 3339
sub common_date_format {
    my $date = shift;
    my $dt   = parse_datetime($date);
    return sprintf( '%04d-%02d-%02d', @$dt{qw(year month day)} );
}

Template::Alloy->define_vmethod( 'text', dt => \&parse_datetime );

Template::Alloy->define_vmethod( 'text', dt_http => \&format_datetime );

Template::Alloy->define_vmethod( 'text',
    dt_date_common => \&common_date_format );

Template::Alloy->define_vmethod(
    'hash',
    pretty_json => sub {

    # Use utf8(0) because Catatlyst expects our view to be a character string.
        Cpanel::JSON::XS->new->utf8(0)->pretty->encode(shift);
    }
);

Template::Alloy->define_vmethod(
    'text',
    decode_punycode => sub {
        my $url_string = shift;
        my $uri        = URI->new($url_string);
        if ( !$uri->scheme ) {
            $uri = URI->new("http://$url_string")
                ;    # default to http:// if no scheme in original...
        }

        # This might fail if somebody adds xmpp:foo@bar.com for example.
        my $host = eval { $uri->ihost };
        if ($@) {
            $host = $url_string;
        }
        return $host;
    }
);

Template::Alloy->define_vmethod(
    'array',
    json => sub {
        Cpanel::JSON::XS::encode_json(shift);
    }
);

Template::Alloy->define_vmethod(
    'array',
    shuffle => sub {
        my $array = shift;
        [ List::Util::shuffle(@$array) ];
    },
);

Template::Alloy->define_vmethod(
    'hash',
    gravatar_image => sub {
        my ( $author, $size, $default ) = @_;
        my ($email)
            = ref $author->{email} ? @{ $author->{email} } : $author->{email};
        Gravatar::URL::gravatar_url(
            email   => $email,
            size    => $size,
            default => Gravatar::URL::gravatar_url(

               # Fallback to the CPAN address, as used by s.c.o, which will in
               # turn fallback to a generated image.
                email   => $author->{pauseid} . '@cpan.org',
                size    => $size,
                default => $default,
            )
        );
    }
);

Template::Alloy->define_vmethod(
    'text',
    digest => sub {
        my ($source) = @_;
        my @source = split( /\//, $source );
        my @target = ( shift @source, shift @source, join( q{/}, @source ) );
        my $digest = Digest::SHA::sha1_base64(
            join( "\0", grep {defined} @target ) );
        $digest =~ tr/[+\/]/-_/;
        return $digest;
    }
);

sub gravatar_fixup {
    my ( $url, $size ) = @_;
    if ( $url
        =~ m{^https?://([a-z0-9.-]+\.)?gravatar\.com/(avatar|userimage)/}i )
    {
        my $url = URI->new($url);
        $url->scheme('https');
        $url->host('secure.gravatar.com');
        if ($size) {
            $url->query_param( s => $size );
        }
        else {
            $url->query_param_delete('s');
        }
        if ( my $fallback = $url->query_param('d') ) {
            $url->query_param( d => gravatar_fixup( $fallback, $size ) );
        }
        return $url->as_string;
    }
    return $url;
}

Template::Alloy->define_vmethod( 'text',
    gravatar_fixup => \&gravatar_fixup, );

Template::Alloy->define_vmethod(
    'text',
    pluralize => sub {
        my ( $text, $count ) = @_;

        # Send args individually since the sub has a prototype.
        $count //= 0;
        return Text::Pluralize::pluralize( $text, $count );
    },
);

Template::Alloy->define_vmethod(
    'text',
    quotemeta => sub {
        return quotemeta( $_[0] );
    },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
