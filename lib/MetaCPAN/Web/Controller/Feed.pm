package MetaCPAN::Web::Controller::Feed;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use XML::Feed;
use HTML::Escape qw/escape_html/;
use DateTime::Format::ISO8601;
use Path::Tiny qw/path/;
use Text::Markdown qw/markdown/;

sub index : PathPart('feed') : Chained('/') : CaptureArgs(0) {
}

sub recent : Chained('index') PathPart Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/recent/index');
    my $data = $c->stash;
    $c->stash->{feed} = $self->build_feed(
        title   => 'Recent CPAN uploads - MetaCPAN',
        entries => $data->{recent}
    );
}

sub news : Chained('index') PathPart Args(0) {
    my ( $self, $c ) = @_;

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^\s+|\s+$//g;
    my @entries;
    foreach my $str ( split /^Title:\s*/m, $news ) {
        next if $str =~ /^\s*$/;

        my %e;
        $e{name} = $str =~ s/\A(.+)$//m ? $1 : 'No title';
        $str =~ s/\A\s*-+//g;
        $e{date}   = $str =~ s/^Date:\s*(.*)$//m ? $1 : '2014-01-01T00:00:00';
        $e{link}   = "http://metacpan.org/news#$e{name}";
        $e{author} = 'METACPAN';
        $str =~ s/^\s*|\s*$//g;

        #$str =~ s{\[([^]]+)\]\(([^)]+)\)}{<a href="$2">$1</a>}g;
        $e{abstract} = $str;
        $e{abstract} = markdown($str);

        push @entries, \%e;
    }

    $c->stash->{feed} = $self->build_feed(
        title   => 'Recent MetaCPAN News',
        entries => \@entries,
    );
}

sub author : Chained('index') PathPart Args(1) {
    my ( $self, $c, $author ) = @_;

    # Redirect to this same action with uppercase author.
    if ( $author ne uc($author) ) {
        $c->res->redirect(

            # NOTE: We're using Args here instead of CaptureArgs :-(.
            $c->uri_for(
                $c->action,  $c->req->captures,
                uc($author), $c->req->params
            ),
            301,    # Permanent
        );
    }

    my $author_cv   = $c->model('API::Author')->get($author);
    my $releases_cv = $c->model('API::Release')->latest_by_author($author);
    my $release_data
        = [ map { $_->{fields} } @{ $releases_cv->recv->{hits}{hits} } ];
    my $author_info = $author_cv->recv;
    my $faves_cv
        = $c->model('API::Favorite')->by_user( $author_info->{user} );
    my $faves_data
        = [ map { $_->{fields} } @{ $faves_cv->recv->{hits}{hits} } ];

    $c->stash->{feed} = $self->build_feed(
        title   => "Recent CPAN activity of $author - MetaCPAN",
        entries => [
            sort { $b->{date} cmp $a->{date} }
                @{ $self->_format_release_entries($release_data) },
            @{ $self->_format_favorite_entries( $author, $faves_data ) }
        ],
    );
}

sub distribution : Chained('index') PathPart Args(1) {
    my ( $self, $c, $distribution ) = @_;
    my $data = $c->model('API::Release')->versions($distribution)->recv;
    $c->stash->{feed} = $self->build_feed(
        title   => "Recent CPAN uploads of $distribution - MetaCPAN",
        entries => [ map { $_->{fields} } @{ $data->{hits}->{hits} } ]
    );
}

sub build_entry {
    my ( $self, $entry ) = @_;
    ref $entry eq 'HASH' or warn 'WRONG ENTRY TYPE';
    for my $k ( keys %{ $entry } ) {
        next unless ref $entry->{$k} eq 'ARRAY';
        $entry->{$k} = $entry->{$k}[0];
    }
    my $e = XML::Feed::Entry->new('RSS');
    $e->title( $entry->{name} );
    $e->link(
        $entry->{link} ||= join( q{/},
            'http://metacpan.org', 'release',
            $entry->{author},      $entry->{name} )
    );
    $e->author( $entry->{author} );
    $e->issued( DateTime::Format::ISO8601->parse_datetime( $entry->{date} ) );
    $e->summary( escape_html( $entry->{abstract} ) );
    return $e;
}

sub build_feed {
    my ( $self, %params ) = @_;
    my $feed = XML::Feed->new( 'RSS', version => 2.0 );
    $feed->title( $params{title} );
    $feed->link('http://metacpan.org/');
    foreach my $entry ( @{ $params{entries} } ) {

        $feed->add_entry( $self->build_entry($entry) );
    }
    return $feed->as_xml;
}

sub _format_release_entries {
    my ( $self, $releases ) = @_;
    my @release_data;
    foreach my $item ( @{$releases} ) {
        $item->{link} = join( q{/},
            'https://metacpan.org', 'release',
            $item->{author},        $item->{name} );
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
        $fav->{link}   = join( q{/},
            'https://metacpan.org', 'release', $fav->{distribution} );
        $fav->{name} = "$author ++ed $fav->{distribution}";
        push( @fav_data, $fav );
    }
    return \@fav_data;
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->content_type('application/rss+xml; charset=UTF-8');
    $c->res->body( $c->stash->{feed} );
}

1;
