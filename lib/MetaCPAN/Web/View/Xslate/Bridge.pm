package MetaCPAN::Web::View::Xslate::Bridge;
use strict;
use warnings;
use parent qw(Text::Xslate::Bridge);

use Text::Xslate::Util qw(mark_raw);
use Number::Format ();
use Ref::Util qw(is_regexpref is_coderef);
use Text::MultiMarkdown       ();
use List::Util                ();
use DateTime                  ();
use With::Roles               ();
use Gravatar::URL             ();
use Text::Pluralize           ();
use MetaCPAN::Web::RenderUtil ();
use overload                  ();

my $num_formatter = Number::Format->new;

sub format_number {
    my ($number) = @_;
    $num_formatter->format_number($number);
}

sub format_bytes {
    my ($number) = @_;
    $num_formatter->format_bytes($number);
}

my $md = Text::MultiMarkdown->new( heading_ids => 1 );

sub markdown {
    my ($text) = @_;
    mark_raw( $md->markdown($text) );
}

sub filter_html {
    my ($html) = @_;
    mark_raw( MetaCPAN::Web::RenderUtil::filter_html("$html") );
}

sub grep {
    my ( $array, $filter ) = @_;

    if ( @_ == 1 ) {
        return [ grep $_, @$array ];
    }
    elsif ( !defined $filter ) {
        return [ grep !defined $_, @$array ];
    }
    elsif ( is_coderef($filter) || overload::Method( $filter, '&{}' ) ) {
        my $sub = \&{$filter};
        return [ grep $sub->($_), @$array ];
    }
    elsif ( is_regexpref($filter) ) {
        return [ grep $_ =~ $filter, @$array ];
    }
    else {
        return [ grep $_ eq $filter, @$array ];
    }
}

sub group_by {
    my ( $array, $key ) = @_;

    my $out = {};
    for my $item (@$array) {
        push @{ $out->{ $item->{$key} } }, $item;
    }

    return $out;
}

sub nsort {
    my ($array) = @_;
    return [ sort { $a <=> $b } @$array ];
}

sub max {
    my ($array) = @_;
    return List::Util::max(@$array);
}

sub sum {
    my ($array) = @_;
    return List::Util::sum0(@$array);
}

sub uniq {
    my ($array) = @_;
    return [ List::Util::uniq(@$array) ];
}

sub int {
    return CORE::int( $_[0] );
}

sub length {
    return CORE::length( $_[0] );
}

my $json = Cpanel::JSON::XS->new->canonical->allow_nonref;

sub json {
    my ($item) = @_;
    $json->encode($item);
}

my $json_pretty = Cpanel::JSON::XS->new->canonical->allow_nonref->pretty;

sub json_pretty {
    my ($item) = @_;
    $json_pretty->encode($item);
}

my $datetime = DateTime->with::roles('MetaCPAN::Web::Role::Date');

sub datetime {
    my $date = shift;
    if ( !defined $date ) {
        return undef;
    }
    if ( ref $date ) {
        if ( !$date->DOES('MetaCPAN::Web::Role::Date') ) {
            $date->with::roles('MetaCPAN::Web::Role::Date');
        }
        return $date;
    }
    elsif ( $date =~ /\A[0-9]+\z/ ) {
        return $datetime->from_epoch( epoch => $date );
    }
    else {
        my $datetime = DateTime::Format::ISO8601->parse_datetime($date);
        my $tz       = $datetime->time_zone;
        $datetime->set_time_zone('GMT')
            if $tz->isa('DateTime::TimeZone::Local')
            || $tz->isa('DateTime::TimeZone::Floating');
        return $datetime->with::roles('MetaCPAN::Web::Role::Date');
    }
}

sub gravatar_image {
    my ( $author, $size ) = @_;
    my $email
        = ( $author && $author->{pauseid} )
        ? $author->{pauseid} . '@cpan.org'
        : '';
    return Gravatar::URL::gravatar_url(
        https   => 1,
        base    => 'https://www.gravatar.com/avatar/',
        email   => $email,
        size    => $size || 80,
        default => 'identicon',
    );
}

sub pluralize {
    my ( $text, $count ) = @_;

    # Send args individually since the sub has a prototype.
    $count //= 0;
    return Text::Pluralize::pluralize( $text, $count );
}

sub indexed_by {
    my ( $array, $key ) = @_;
    return { map +( $_->{$key} => $_ ), @$array };
}

sub decode_punycode {
    my ($url_string) = @_;
    eval {
        my $uri = URI->new($url_string);
        if ( !$uri->scheme ) {

            # default to http:// if no scheme in original...
            $uri = URI->new("http://$url_string");
        }
        eval { $uri->ihost } || $uri->host;
    } || $url_string;
}

sub slice {
    my ( $array, $start, $end ) = @_;
    return [ @{$array}[ $start .. ( $end >= 0 ? $end : $#$array + $end ) ] ];
}

sub version {
    my ($v) = @_;
    eval { version->parse($v)->normal } || $v;
}

sub is_url {
    my ($url) = @_;
    return $url
        && $url
        =~ /^(?:bzr|https?|git\+ssh|svn|ssh|svn\+ssh|mailto|git|irc):/;
}

sub shuffle {
    my ($array) = @_;
    return [ List::Util::shuffle(@$array) ];
}

no strict 'refs';
__PACKAGE__->bridge(
    scalar => {
        map +( $_ => \&$_ ), qw(
            filter_html
            format_number
            format_bytes
            markdown
            int
            json
            json_pretty
            decode_punycode
            version
            is_url
            length
        ),
    },
    function => {
        map +( $_ => \&$_ ), qw(
            filter_html
            format_number
            format_bytes
            markdown
            datetime
            gravatar_image
            pluralize
            version
            is_url
            length
        ),
    },
    array => {
        map +( $_ => \&$_ ), qw(
            grep
            group_by
            nsort
            max
            sum
            uniq
            json
            json_pretty
            indexed_by
            slice
            shuffle
        ),
    },
    hash => {
        map +( $_ => \&$_ ), qw(
            json
            json_pretty
        ),
    },
);

1;
