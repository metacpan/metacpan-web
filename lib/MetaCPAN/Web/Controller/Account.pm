package MetaCPAN::Web::Controller::Account;

use Moose;
use DateTime ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->cdn_never_cache(1);

    if ( my $token = $c->token ) {
        $c->authenticate( { token => $token } );
    }
    unless ( $c->user_exists ) {
        $c->forward('/forbidden');
    }
    return $c->user_exists;
}

sub logout : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    $c->req->session->expire;
    $c->res->redirect(q{/});
}

sub settings : Local : Args(0) {
    my ( $self, $c ) = @_;
}

sub identities : Local : Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST'
        && ( my $delete = $c->req->params->{delete} ) )
    {
        $c->model('API::User')->delete_identity( $delete, $c->token )->get;
        $c->res->redirect('/account/identities');
    }
}

sub profile : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $author = $c->model('API::User')->get_profile( $c->token )->get;
    $c->stash(
        $author->{error} ? { no_profile => 1 } : { author => $author } );
    my $req = $c->req;
    return unless ( $req->method eq 'POST' );

    my $data = $author;

    my @blog_url  = $req->param('blog.url');
    my @blog_feed = $req->param('blog.feed');
    $data->{blog}
        = $req->param('blog.url')
        ? [
        map +{ url => $blog_url[$_], feed => $blog_feed[$_] },
        ( 0 .. $#blog_url )
        ]
        : undef;

    my @donation_name = $req->param('donation.name');
    my @donation_id   = $req->param('donation.id');
    $data->{donation}
        = $req->param('donation.name')
        ? [
        map +{ name => $donation_name[$_], id => $donation_id[$_] },
        ( 0 .. $#donation_name )
        ]
        : undef;

    my @profile_name = $req->param('profile.name');
    my @profile_id   = $req->param('profile.id');
    $data->{profile}
        = $req->param('profile.name')
        ? [
        map +{ name => $profile_name[$_], id => $profile_id[$_] },
        ( 0 .. $#profile_name )
        ]
        : undef;

    $data->{location}
        = $req->params->{latitude}
        ? [ $req->params->{latitude}, $req->params->{longitude} ]
        : undef;
    $data->{$_} = $req->params->{$_} eq q{} ? undef : $req->params->{$_}
        for (qw(name asciiname city region country));
    $data->{$_} = [ grep {$_} $req->param($_) ] for (qw(website email));

    $data->{extra} = $req->param('extra') ? $req->json_param('extra') : undef;

    $data->{donation} = undef unless ( $req->params->{donations} );

    my $res = $c->model('API::User')->update_profile( $data, $c->token )->get;
    if ( $res->{error} ) {
        $c->stash( { author => $data, errors => $res->{errors} } );
    }
    else {
        $c->stash( { success => 1, author => $res } );
    }
}

__PACKAGE__->meta->make_immutable;

1;
