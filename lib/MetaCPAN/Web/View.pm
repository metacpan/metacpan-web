package MetaCPAN::Web::View;
use strict;
use warnings;
use base 'Template::Alloy';
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
        Gravatar::URL::gravatar_url(
            email   => $author->{email},
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

sub new {
    my $class = shift;
    return $class->next::method(
        @_,
        INCLUDE_PATH => ['templates'],
        TAG_STYLE    => 'asp',
        COMPILE_DIR  => 'var/tmp/templates',
        COMPILE_PERL => 1,
        STAT_TTL     => 1,
        CACHE_SIZE   => $ENV{PLACK_ENV}
            && $ENV{PLACK_ENV} eq 'development' ? 0 : undef,
        WRAPPER     => [qw(wrapper.html)],
        ENCODING    => 'utf8',
        AUTO_FILTER => 'html',
        PRE_PROCESS => ['preprocess.html'],
    );
}

1;
