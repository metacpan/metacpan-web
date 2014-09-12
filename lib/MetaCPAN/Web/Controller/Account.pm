package MetaCPAN::Web::Controller::Account;

use Moose;
use List::MoreUtils qw(pairwise);
use DateTime      ();
use JSON::MaybeXS ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;
    unless ( $c->user_exists ) {
        $c->forward('/forbidden');
    }
    return $c->user_exists;
}

sub logout : Local {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    $c->req->session->expire;
    $c->res->redirect(q{/});
}

sub settings : Local {
    my ( $self, $c ) = @_;
}

sub identities : Local {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST'
        && ( my $delete = $c->req->params->{delete} ) )
    {
        $c->model('API::User')->delete_identity( $delete, $c->token )->recv;
        $c->res->redirect('/account/identities');
    }
}

sub profile : Local {
    my ( $self, $c ) = @_;
    my $author = $c->model('API::User')->get_profile( $c->token )->recv;
    $c->stash(
        $author->{error} ? { no_profile => 1 } : { author => $author } );
    my $req = $c->req;
    return unless ( $req->method eq 'POST' );

    my $data = $author;
    $data->{blog}
        = $req->param('blog.url')
        ? [
        pairwise { { url => $a, feed => $b } }
        @{ [ $req->param('blog.url') ] },
        @{ [ $req->param('blog.feed') ] }
        ]
        : undef;
    $data->{donation}
        = $req->param('donation.name')
        ? [
        pairwise { { name => $a, id => $b } }
        @{ [ $req->param('donation.name') ] },
        @{ [ $req->param('donation.id') ] }
        ]
        : undef;
    $data->{profile}
        = $req->param('profile.name')
        ? [
        pairwise { { name => $a, id => $b } }
        @{ [ $req->param('profile.name') ] },
        @{ [ $req->param('profile.id') ] }
        ]
        : undef;

    $data->{location}
        = $req->params->{latitude}
        ? [ $req->params->{latitude}, $req->params->{longitude} ]
        : undef;
    $data->{$_} = $req->params->{$_} eq q{} ? undef : $req->params->{$_}
        for (qw(name asciiname gravatar_url city region country));
    $data->{$_} = [ grep {$_} $req->param($_) ] for (qw(website email));
    $data->{extra} = eval {
        JSON::MaybeXS->new->relaxed->utf8->decode( $req->params->{extra} );
    };
    $data->{donation} = undef unless ( $req->params->{donations} );

    my $res
        = $c->model('API::User')->update_profile( $data, $c->token )->recv;
    if ( $res->{error} ) {
        $c->stash( { author => $data, errors => $res->{errors} } );
    }
    else {
        $c->stash( { success => 1, author => $res } );
    }
}

1;
