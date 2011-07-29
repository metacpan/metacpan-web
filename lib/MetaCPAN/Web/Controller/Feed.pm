package MetaCPAN::Web::Controller::Feed;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use XML::Feed;
use DateTime::Format::ISO8601;
use AnyEvent;

sub index : PathPart('feed') : Chained('/') : CaptureArgs(0) {
}

sub recent : Chained('index') : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/recent/index');
    my $data = $c->stash;
    $c->stash->{feed} = $self->build_feed(
        title   => 'Recent CPAN uploads - MetaCPAN',
        entries => $data->{recent}
    );
}

sub author : Chained('index') : Path : Args(1) {
    my ( $self, $c, $author ) = @_;
    $c->forward( '/author/index', [$author] );
    my $data = $c->stash;
    $c->stash->{feed} = $self->build_feed(
        title => "Recent CPAN uploads by $data->{author}->{name} - MetaCPAN",
        entries => $data->{releases}
    );
}

sub distribution : Chained('index') : Path : Args(1) {
    my ( $self, $c, $distribution ) = @_;
    my $versions = $c->model('API')->release->versions($distribution)->recv;
    $c->stash->{feed} = $self->build_feed(
        title   => "Recent CPAN uploads of $distribution - MetaCPAN",
        entries => $versions->fields,
    );
}

sub build_entry {
    my ( $self, $entry ) = @_;
    my $e = XML::Feed::Entry->new('RSS');
    $e->title( $entry->{name} );
    $e->link(
        join( '/',
            'http://metacpan.org', 'release',
            $entry->{author},      $entry->{name} )
    );
    $e->author( $entry->{author} );
    $e->issued( DateTime::Format::ISO8601->parse_datetime( $entry->{date} ) );
    $e->summary( $entry->{abstract} );
    return $e;
}

sub build_feed {
    my ( $self, %params ) = @_;
    my $cv = AE::cv;
    my $feed = XML::Feed->new( 'RSS', version => 2.0 );
    $feed->title( $params{title} );
    $feed->link('http://metapcan.org/');
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
