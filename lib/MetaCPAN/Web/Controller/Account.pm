package MetaCPAN::Web::Controller::Account;

use Moose;
use DateTime ();

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->res->header( 'Vary', 'Cookie' );

    my $attrib = $c->action->attributes;
    my $auth   = $attrib->{Auth} && $attrib->{Auth}[0] // 1;
    if ( my $user = $c->user ) {
        $c->cdn_never_cache(1);

        if ( my $user_id = $user->id ) {
            $c->add_surrogate_key("user/$user_id");
        }
        $c->stash( { user => $user } );
    }
    elsif ($auth) {
        $c->forward('/forbidden');
        return 0;
    }
    return 1;
}

sub login_status : Local : Args(0) : Auth(0) {
    my ( $self, $c ) = @_;
    $c->stash( { current_view => 'JSON' } );

    if ( $c->user ) {
        $c->stash->{json}{logged_in} = \1;
        $c->forward('/account/favorite/list_as_json');
    }
    else {
        $c->stash->{json}{logged_in} = \0;
        $c->cdn_max_age('30d');
    }
}

sub logout : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    $c->logout;
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
        $c->user->delete_identity($delete)->get;
        $c->res->redirect('/account/identities');
    }
}

sub profile : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $user   = $c->user;
    my $author = $user->get_profile->get;
    $c->stash( {
        ( $author->{error} ? ( no_profile => 1 ) : ( author => $author ) ),
        profiles => $c->model('API::Author')->profile_data,
    } );

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

    # validation
    my @form_errors;
    push @form_errors,
        {
        field   => 'asciiname',
        message => "ASCII name must only have ASCII characters",
        }
        if defined $data->{asciiname}
        and $data->{asciiname} =~ /[^\x20-\x7F]/;
    if (@form_errors) {
        $c->stash( { author => $data, errors => \@form_errors } );
        return;
    }

    my $res = $user->update_profile($data)->get;
    if ( $res->{error} ) {
        $c->stash( { author => $data, errors => $res->{errors} } );
    }
    else {
        $c->purge_author_key( $data->{pauseid} ) if exists $data->{pauseid};
        $c->stash( { success => 1, author => $res } );
    }
}

__PACKAGE__->meta->make_immutable;

1;
