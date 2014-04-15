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

    my $file = $c->config->{home} . '/News';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^\s+|\s+$//g;
    my @entries;
    foreach my $str (split /^Title:\s*/m, $news) {
        next if $str =~ /^\s*$/;

        my %e;
        $e{name} = $str =~ s/\A(.+)$//m ? $1 : 'No title';
        $str =~ s/\A\s*-+//g;
        $e{date} = $str =~ s/^Date:\s*(.*)$//m ? $1 : '2014-01-01T00:00:00';
        $e{link} = "http://metacpan.org/news#$e{name}";
        $e{author} = 'METACPAN';
        $str =~ s/^\s*|\s*$//g;
        #$str =~ s{\[([^]]+)\]\(([^)]+)\)}{<a href="$2">$1</a>}g;
        $e{abstract} = $str;
        $e{abstract} = markdown($str);

        push @entries, \%e;
    }

    $c->stash->{feed} = $self->build_feed(
        title => "Recent MetaCPAN News",
        entries => \@entries,
    );
}

sub author : Chained('index') PathPart Args(1) {
    my ( $self, $c, $author ) = @_;

    # Redirect to this same action with uppercase author.
    if( $author ne uc($author) ){
        $c->res->redirect(
            # NOTE: We're using Args here instead of CaptureArgs :-(.
            $c->uri_for($c->action, $c->req->captures, uc($author), $c->req->params),
            301, # Permanent
        );
    }

    my $author_cv   = $c->model('API::Author')->get($author);
    my $releases_cv = $c->model('API::Release')->latest_by_author($author);
    my $data        = {
        author   => $author_cv->recv,
        releases => [ map { $_->{fields} } @{ $releases_cv->recv->{hits}{hits} } ],
    };

    $c->stash->{feed} = $self->build_feed(
        title => "Recent CPAN uploads by $data->{author}->{name} - MetaCPAN",
        entries => $data->{releases}
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
    my $e = XML::Feed::Entry->new('RSS');
    $e->title( $entry->{name} );
    $e->link(
        $entry->{link} //
        join( '/',
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

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->content_type('application/rss+xml; charset=UTF-8');
    $c->res->body( $c->stash->{feed} );
}

1;
