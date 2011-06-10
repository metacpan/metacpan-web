package MyCondVar;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use AnyEvent;
use base 'AnyEvent::CondVar';

$AnyEvent::HTTP::PERSISTENT_TIMEOUT = 0;
$AnyEvent::HTTP::USERAGENT
    = 'Mozilla/5.0 (compatible; U; MetaCPAN-Web/1.0; +https://github.com/CPAN-API/metacpan-web)';

use overload
    '&{}'    => \&build,
    '|'      => \&any,
    '&'      => \&all,
    fallback => 1;

sub build {
    my $self = shift;
    return sub {
        my $cb   = shift;
        my $void = !defined wantarray;
        my $res  = MyCondVar->new unless ($void);
        if ( my $data = $self->ready ) {
            $cb->($data);
            return $res;
        }
        my $ae_cb = $void ? $cb : sub {
            my $data = $cb->(shift);
            if ( blessed $data && $data->isa('MyCondVar') ) {
                $data->chain_cb(
                    sub {
                        $res->send( shift->recv );
                    }
                );
            }
            else {
                $res->send($data);
            }
        };
        $self->chain_cb($ae_cb);
        return $res;
    };
}

sub chain_cb {
    my ( $self, $cb ) = @_;
    my $self_cb = $self->{_ae_cb};
    $self->{_ae_cb} = $self_cb
        ? sub {
        $self_cb->(@_);
        $cb->(@_);
        }
        : $cb;
}

sub any {
    my ( $self, $or ) = @_;
    my $done = 0;
    my $res  = MyCondVar->new;
    my $cb   = sub {
        $res->send( shift->recv ) unless ( $done++ );
    };
    $self->chain_cb($cb);
    $or->chain_cb($cb);
    return $res;
}

sub all {
    my ( $self, $and ) = @_;
    my @done;
    my $res = MyCondVar->new;
    $self->chain_cb(
        sub {
            my @data = shift->recv;
            @done ? $res->send( @data, @done ) : ( @done = @data );
        }
    );
    $and->chain_cb(
        sub {
            my @data = shift->recv;
            @done ? $res->send( @done, @data ) : ( @done = @data );
        }
    );
    return $res;
}

package MetaCPAN::Web::Model;
use strict;
use warnings;
use Test::More;
use JSON;
use AnyEvent::HTTP qw(http_request);

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub request {
    my ( $self, $path, $search, $params ) = @_;
    my $req = $self->cv;
    http_request $search ? 'post' : 'get' => $self->{url} . $path,
        body => $search ? encode_json($search) : '', persistent => 1, sub {
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

sub cv {
    MyCondVar->new;
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
