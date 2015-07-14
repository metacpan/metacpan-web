package MetaCPAN::Web::Controller::Feed;

use Moose;
use namespace::autoclean;
use feature qw( state );

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime::Format::ISO8601 ();
use HTML::Escape qw/escape_html/;
use MetaCPAN::Web::Types qw( ArrayRef HashRef Str Uri );
use Params::ValidationCompiler qw( validation_for );
use Path::Tiny qw/path/;
use Text::Markdown qw/markdown/;
use XML::Feed ();

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

sub feed_index : PathPart('feed') : Chained('/') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub recent : Chained('feed_index') PathPart Args(0) {
    my ( $self, $c ) = @_;

    # Set surrogate key and ttl from here as well
    $c->forward('/recent/index');

    $c->stash->{feed} = $self->build_feed(
        entries => $c->stash->{recent},
        host    => URI->new( $c->config->{web_host} ),
        title   => 'Recent CPAN uploads - MetaCPAN',
    );
}

sub news : Local : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('NEWS');
    $c->browser_max_age('1h');
    $c->cdn_max_age('1h');

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^\s+|\s+$//g;
    my @entries;
    foreach my $str ( split /^Title:\s*/m, $news ) {
        next if $str =~ /^\s*$/;

        my %e;
        $e{name} = $str =~ s/\A(.+)$//m ? $1 : 'No title';

        # Use the same processing as _Header2Label in
        # Text::MultiMarkdown
        my $a_name = lc $e{name};
        $a_name =~ s/[^A-Za-z0-9:_.-]//g;
        $a_name =~ s/^[^a-z]+//gi;

        $str =~ s/\A\s*-+//g;
        $e{date} = $str =~ s/^Date:\s*(.*)$//m ? $1 : '2014-01-01T00:00:00';
        $e{link} = '/news';
        $e{fragment} = $a_name;
        $e{author}   = 'METACPAN';
        $str =~ s/^\s*|\s*$//g;

        #$str =~ s{\[([^]]+)\]\(([^)]+)\)}{<a href="$2">$1</a>}g;
        $e{abstract} = $str;
        $e{abstract} = markdown($str);

        push @entries, \%e;
    }

    $c->stash->{feed} = $self->build_feed(
        entries => \@entries,
        host    => $c->config->{web_host},
        title   => 'Recent MetaCPAN News',
    );
}

sub author : Local : Args(1) {
    my ( $self, $c, $author ) = @_;

    # Redirect to this same action with uppercase author.
    if ( $author ne uc($author) ) {

        $c->browser_max_age('7d');
        $c->cdn_max_age('1y');
        $c->add_surrogate_key('REDIRECT_FEED');

        $c->res->redirect(

            # NOTE: We're using Args here instead of CaptureArgs :-(.
            $c->uri_for(
                $c->action,  $c->req->captures,
                uc($author), $c->req->params
            ),
            301,    # Permanent
        );
    }

    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');
    $c->add_author_key($author);

    my $author_info = $c->model('API::Author')->get($author)->get;

    # If the author can be found, we get the hashref of author info.  If it
    # can't be found, we (confusingly) get a HashRef with "code" and "message"
    # keys.

    if ( $author_info->{code} && $author_info->{code} == 404 ) {
        $c->detach( '/not_found', [] );
    }

    my $releases = $c->model('API::Release')->latest_by_author($author);

    my $faves = $c->model('API::Favorite')->by_user( $author_info->{user} );

    $c->stash->{feed} = $self->build_feed(
        host    => $c->config->{web_host},
        title   => "Recent CPAN activity of $author - MetaCPAN",
        entries => [
            sort { $b->{date} cmp $a->{date} }
                @{ $self->_format_release_entries( $releases->{releases} ) },
            @{ $self->_format_favorite_entries( $author, $faves ) }
        ],
    );
}

sub distribution : Local : Args(1) {
    my ( $self, $c, $distribution ) = @_;

    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');
    $c->add_dist_key($distribution);

    my $data = $c->model('API::Release')->versions($distribution)->get;
    $c->stash->{feed} = $self->build_feed(
        host    => $c->config->{web_host},
        title   => "Recent CPAN uploads of $distribution - MetaCPAN",
        entries => [
            map { single_valued_arrayref_to_scalar($_) }
            map { $_->{fields} } @{ $data->{hits}->{hits} }
        ]
    );
}

sub build_entry {
    my $self = shift;

    state $check = validation_for(
        params => {
            entry => { type => HashRef },
            host  => { type => Uri },
        }
    );

    my %args  = $check->(@_);
    my $entry = $args{entry};

    my $e = XML::Feed::Entry->new('RSS');

    my $link = $args{host}->clone;
    $link->path( $entry->{link}
            || join( q{/}, 'release', $entry->{author}, $entry->{name} ) );
    $link->fragment( $entry->{fragment} ) if $entry->{fragment};    # for news
    $e->link( $link->as_string );

    $e->author( $entry->{author} );
    $e->issued( DateTime::Format::ISO8601->parse_datetime( $entry->{date} ) );
    $e->summary( escape_html( $entry->{abstract} ) );
    $e->title( $entry->{name} );
    return $e;
}

sub build_feed {
    my $self = shift;

    state $check = validation_for(
        params => {
            entries => { type => ArrayRef },
            host    => { type => Uri, optional => 0, },
            title   => { type => Str },
        }
    );

    my %params = $check->(@_);

    my $feed = XML::Feed->new( 'RSS', version => 2.0 );
    $feed->title( $params{title} );
    $feed->link('/');

    foreach my $entry ( @{ $params{entries} } ) {
        $feed->add_entry(
            $self->build_entry( entry => $entry, host => $params{host} ) );
    }
    return $feed->as_xml;
}

sub _format_release_entries {
    my ( $self, $releases ) = @_;
    my @release_data;
    foreach my $item ( @{$releases} ) {
        $item->{link}
            = join( q{/}, 'release', $item->{author}, $item->{name} );
        $item->{name} = "$item->{author} has released $item->{name}";
        push( @release_data, $item );
    }
    return \@release_data;
}

sub _format_favorite_entries {
    my ( $self, $author, $data ) = @_;
    my @fav_data;
    foreach my $fav ( @{$data} ) {
        $fav->{abstract}
            = "$author ++ed $fav->{distribution} from $fav->{author}";
        $fav->{author} = $author;
        $fav->{link}   = join( q{/}, 'release', $fav->{distribution} );
        $fav->{name}   = "$author ++ed $fav->{distribution}";
        push( @fav_data, $fav );
    }
    return \@fav_data;
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->content_type('application/rss+xml; charset=UTF-8');
    $c->res->body( $c->stash->{feed} );

}

__PACKAGE__->meta->make_immutable;

1;
