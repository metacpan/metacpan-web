package MetaCPAN::Web::View::HTML;

use strict;
use warnings;
use base 'Catalyst::View::TT::Alloy';

use mro;
use DateTime;
use Digest::MD5 qw(md5_hex);
use DateTime::Format::HTTP;
use DateTime::Format::ISO8601;
use URI;
use JSON;
use Gravatar::URL;

sub parse_datetime {
    my $date = shift;
    $date =~ s/\..*?$//;
    return unless ($date);
    DateTime::Format::ISO8601->parse_datetime($date);
}

sub format_datetime {
    my $date = shift;
    my $dt   = parse_datetime($date);
    return unless $dt;
    DateTime::Format::HTTP->format_datetime($dt);
}

Template::Alloy->define_vmethod( 'text', dt => \&parse_datetime );

Template::Alloy->define_vmethod( 'text', dt_http => \&format_datetime );

Template::Alloy->define_vmethod(
    'text',
    to_color => sub {
        my $md5 = md5_hex( md5_hex(shift) );
        my $color = substr( $md5, 0, 6 );
        return "#$color";
    },
);

Template::Alloy->define_vmethod(
    'text',
    decode_punycode => sub {
        URI->new(shift)->ihost;
    }
);

Template::Alloy->define_vmethod(
    'array',
    json => sub {
        JSON::encode_json(shift);
    }
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

