package MetaCPAN::Web::View::HTML;

use Moose;
extends 'Catalyst::View::TT::Alloy';

use version;
use Digest::SHA;
use List::Util       ();
use Cpanel::JSON::XS ();
use Gravatar::URL;
use MetaCPAN::Web::RenderUtil 'filter_html';
use Regexp::Common qw(time);
use Number::Format;
use Template::Plugin::DateTime;
use Template::Plugin::Page;
use Text::MultiMarkdown;
use Text::Pluralize ();
use URI;
use URI::QueryParam;

has api_public => (
    is       => 'ro',
    required => 1,
);
has source_host => (
    is       => 'ro',
    required => 1,
);

sub COMPONENT {
    my ( $class, $app, $args ) = @_;

    $args = $class->merge_config_hashes(
        {
            api_public  => $app->config->{api_public} || $app->config->{api},
            source_host => $app->config->{source_host},
        },
        $args,
    );
    return $class->SUPER::COMPONENT( $app, $args );
}

around render => sub {
    my ( $orig, $self, $c, $template, $args ) = @_;

    my $vars = { $args ? %$args : %{ $c->stash } };

    my $req = $c->req;

    $vars->{api_public}  = $self->api_public;
    $vars->{source_host} = $self->source_host;
    $vars->{assets}      = $req->env->{'psgix.assets'} || [];
    $vars->{req}         = $req;
    $vars->{oauth_prefix}
        = $self->api_public
        . '/oauth2/authorize?client_id='
        . $c->config->{consumer_key};
    $vars->{site_alert_message} = $c->config->{site_alert_message};
    $vars->{page_url}           = sub {
        @_ ? $req->uri_with(@_) : $req->uri->clone;
    };

    return $self->$orig( $c, $template, $vars );
};

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
    my $dt   = parse_datetime($date)
        or return undef;
    my ( $year, $month, $day ) = @$dt{qw(year month day)};

    return undef
        unless defined $year && defined $month && defined $day;
    return sprintf( '%04d-%02d-%02d', $year, $month, $day );
}

my $md_render = Text::MultiMarkdown->new( heading_ids => 1 );
Template::Alloy->define_vmethod(
    'text',
    markdown => sub {
        my $md = shift;
        $md_render->markdown($md);
    }
);

Template::Alloy->define_vmethod(
    'text',
    is_url => sub {
        my $url = shift;
        return $url
            && $url
            =~ /^(?:bzr|https?|git\+ssh|svn|ssh|svn\+ssh|mailto|git|irc):/;
    }
);

Template::Alloy->define_vmethod(
    'text',
    version => sub {
        my $v = shift;
        eval { version->parse($v)->normal } || $v;
    }
);

my $formatter = Number::Format->new;
Template::Alloy->define_vmethod(
    'text',
    format_number => sub {
        my ($number) = @_;
        $formatter->format_number($number);
    },
);

Template::Alloy->define_vmethod(
    'text',
    format_bytes => sub {
        my ($number) = @_;
        $formatter->format_bytes($number);
    },
);

Template::Alloy->define_vmethod( 'text', dt => \&parse_datetime );

Template::Alloy->define_vmethod( 'text', dt_http => \&format_datetime );

Template::Alloy->define_vmethod( 'text',
    dt_date_common => \&common_date_format );

Template::Alloy->define_vmethod(
    'text',
    decode_punycode => sub {
        my $url_string = shift;
        eval {
            my $uri = URI->new($url_string);
            if ( !$uri->scheme ) {
                $uri = URI->new("http://$url_string")
                    ;    # default to http:// if no scheme in original...
            }
            my $host = $uri->host && eval { $uri->ihost };
            if ( !$host ) {
                $host = $url_string;
            }
            return $host;
        } || $url_string;
    }
);

my $json = Cpanel::JSON::XS->new->canonical->allow_nonref;
Template::Alloy->define_vmethod( $_, json => sub { $json->encode( $_[0] ) } )
    for 'text', 'array', 'hash';

my $pretty_json = Cpanel::JSON::XS->new->canonical->pretty->allow_nonref;
Template::Alloy->define_vmethod( $_,
    pretty_json => sub { $json->encode( $_[0] ) } )
    for 'text', 'array', 'hash';

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
);

Template::Alloy->define_vmethod(
    'text',
    digest => sub {
        my ($source) = @_;
        my @source = split( /\//, $source );
        my @target = ( shift @source, shift @source, join( q{/}, @source ) );
        my $digest = Digest::SHA::sha1_base64( join(
            "\0", grep {defined} @target ) );
        $digest =~ tr/[+\/]/-_/;
        return $digest;
    }
);

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

Template::Alloy->define_vmethod( 'text', filter_html => \&filter_html );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
