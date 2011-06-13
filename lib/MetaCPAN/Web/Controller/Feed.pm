package MetaCPAN::Web::Controller::Feed;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use XML::Feed;
use DateTime::Format::ISO8601;

sub index {
    my ( $self, $req ) = @_;
    if ( $req->path eq '/feed/recent' ) {
        return $self->recent($req);
    }
    elsif ( $req->path =~ /\/feed\/author\/([^\/]+)\/?$/ ) {
        return $self->author( $req, $1 );
    }
    elsif ( $req->path =~ /\/feed\/distribution\/([^\/]+)\/?$/ ) {
        return $self->distribution( $req, $1 );
    }
    my $cv = AE::cv;
    $cv->send( $self->not_found($req) );
    return $cv;
}

sub recent {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    $self->controller('Recent')->index($req)->cb(
        sub {
            my $data = shift->recv;
            my $feed = $self->build_feed(
                request => $req,
                title   => 'Recent CPAN uploads - MetaCPAN',
                entries => $data->{recent}
            );
            $cv->send($feed);

        }
    );
    return $cv;
}

sub author {
    my ( $self, $req, $author ) = @_;
    my $cv = AE::cv;
    $self->controller('Author')->index( $req->clone( PATH_INFO => "/$author" ) )
      ->cb(
        sub {
            my $data = shift->recv;
            unless ( $data->{author} ) {
                $cv->send( $self->not_found($req) );
                return;
            }
            my $feed = $self->build_feed(
                request => $req,
                title =>
                  "Recent CPAN uploads by $data->{author}->{name} - MetaCPAN",
                entries => $data->{releases}
            );
            $cv->send($feed);

        }
      );
    return $cv;
}

sub distribution {
    my ( $self, $req, $distribution ) = @_;
    my $cv = AE::cv;
    $self->model('Release')->versions($distribution)->(
        sub {
            my $data = shift->recv;
            unless ( $data->{hits}->{total} ) {
                $cv->send( $self->not_found($req) );
                return;
            }
            my $feed = $self->build_feed(
                request => $req,
                title   => "Recent CPAN uploads of $distribution - MetaCPAN",
                entries => [ map { $_->{fields} } @{ $data->{hits}->{hits} } ]
            );
            $cv->send($feed);
        }
    );
    return $cv;
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
    return $params{request}->new_response(
        200,
        [ 'Content-type' => 'application/rss+xml' ],
        [ $feed->as_xml ]
    );
}

1;
