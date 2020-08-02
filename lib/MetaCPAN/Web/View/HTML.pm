package MetaCPAN::Web::View::HTML;

use Moose;
extends 'Catalyst::View::TT::Alloy';

use version;
use DateTime;
use DateTime::Format::ISO8601;
use Digest::SHA;
use List::Util       ();
use Cpanel::JSON::XS ();
use Gravatar::URL;
use MetaCPAN::Web::RenderUtil 'filter_html';
use Regexp::Common qw(time);
use Number::Format;
use Text::MultiMarkdown;
use Text::Pluralize ();
use URI;
use URI::QueryParam;
use With::Roles;

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

my $datetime = DateTime->with::roles('MetaCPAN::Web::Role::Date');
Template::Alloy->define_vmethod(
    'text',
    datetime => sub {
        my $date = shift;
        return undef if !defined $date;
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
            my $datetime
                = eval { DateTime::Format::ISO8601->parse_datetime($date) };
            return undef if !$datetime;
            my $tz = $datetime->time_zone;
            $datetime->set_time_zone('UTC')
                if $tz->isa('DateTime::TimeZone::Local')
                || $tz->isa('DateTime::TimeZone::Floating');
            return $datetime->with::roles('MetaCPAN::Web::Role::Date');
        }
    }
);

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
