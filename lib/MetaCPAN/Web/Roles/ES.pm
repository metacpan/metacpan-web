package MetaCPAN::Web::Roles::ES;

use Moose::Role;

use MetaCPAN::Web::MyCondVar;
use Test::More;
use JSON;
use AnyEvent::HTTP qw(http_request);
use Module::Find qw(findallmod);

sub cv {
    MetaCPAN::Web::MyCondVar->new;
}

sub request {
    my ( $self, $path, $search, $params ) = @_;
    my $req = $self->cv;
    http_request $search ? 'post' : 'get' => $self->{url} . $path,
      body => $search ? encode_json($search) : '',
      persistent => 1,
      sub {
        my ( $data, $headers ) = @_;
        my $content_type = $headers->{'content-type'} || '';

        if ( $content_type eq 'application/json' ) {
            my $json = eval { decode_json($data) };
            $req->send( $@ ? { raw => $data } : $json );
        }
        else {

            # Response is raw data, e.g. text/plain
            $req->send( { raw => $data } );
        }
      };
    return $req;
}

1;

__END__

my $cv = AE::cv;

my $module = metacpan '/module/DBIx::Class::ResultSet';


my $author = $module->(
    sub {
        my $author = shift->{_source}->{author};
        print "Author of DBIx::Class::ResultSet is $author", $/;
        metacpan '/author/' . $author;
} );

$author->(sub {
    my $res = shift->{_source};
    print "His name is $res->{name}", $/;
});

my $dists = $author->(sub {
    my $res = shift->{_source};
    metacpan '/dist/_search?q=author:' . $res->{pauseid};
});

$dists->(sub {
    my $res = shift;
    print "He has ", $res->{hits}->{total}, " distributions:", $/;
    foreach my $dist (@{$res->{hits}->{hits}}) {
        print " * $dist->{_id}", $/;
    }
});

my $rating = $module->(sub {
    metacpan '/cpanratings/' . shift->{_source}->{distname};
});

$rating->(sub {
    my $res = shift->{_source};
    print "Rating for $res->{dist} is $res->{rating} ($res->{review_count} reviews)", $/;
});

($rating & $dists)->(sub { 
    $cv->send;
});

$cv->recv;
done_testing;
exit;

my $author1 = $module->(
    sub {
        my $res = shift;
        metacpan '/author/' . $res->{_source}->{author};
    } );

my $author2 = $author1->(
    sub {
        my $res = shift;
        metacpan '/author/MLEHMANN';
    } );

my $author3 = $author1->(
    sub {
        metacpan '/author/PERLER';
    } );

isa_ok( $author1, 'AnyEvent::CondVar' );

my $any = $author3 | $author2 | $author1;
my $all = $author3 & $author2 & $author1;

my $first = 0;

$all->(
    sub {
        ok( $first, '$all is called after $any' );
        is( @_,                   3,       'three results' );
        is( $_[ $_->[0] ]->{_id}, $_->[1], "$_->[1] is at $_->[0]" )
          for ( [ 0, 'PERLER' ], [ 1, 'MLEHMANN' ], [ 2, 'ABRAXXA' ] );
    } );
$any->(
    sub {
        ok( !$first++, '$any is called before $all' );
        is( ( scalar grep { $_ eq $_[0]->{_id} } qw(ABRAXXA PERLER MLEHMANN) ),
            1,
            'result is one of the authors' );
    } );

$cv->recv;

done_testing;
