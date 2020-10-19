package MetaCPAN::Web::Controller::Account;

use Moose;
use DateTime ();
use Colouring::In;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->res->header( 'Vary', 'Cookie' );

    if ( my $token = $c->token ) {
        $c->authenticate( { token => $token } );
    }
    my $attrib = $c->action->attributes;
    my $auth   = $attrib->{Auth} && $attrib->{Auth}[0] // 1;
    if ( $c->user_exists ) {
        $c->cdn_never_cache(1);

        if ( my $user_id = $c->user && $c->user->id ) {
            $c->add_surrogate_key("user/$user_id");
        }
        $c->stash( { user => $c->user } );
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
    delete $c->stash->{user};

    if ( $c->user_exists ) {
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

    my $res = $c->model('API::User')->update_profile( $data, $c->token )->get;
    if ( $res->{error} ) {
        $c->stash( { author => $data, errors => $res->{errors} } );
    }
    else {
        $c->purge_author_key( $data->{pauseid} ) if exists $data->{pauseid};
        $c->stash( { success => 1, author => $res } );
    }
}

sub theme : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $author = $c->model('API::User')->get_profile( $c->token )->get;
    $c->stash( {
        ( $author->{error} ? ( no_profile => 1 ) : ( author => $author ) ),
        profiles => $c->model('API::Author')->profile_data,
    } );

    my $req = $c->req;
    unless ( $req->method eq 'POST' ) {
        if ( $req->headers->header('Content-Type') eq 'application/json' ) {
            $c->stash( { current_view => 'JSON' } );
            $c->stash->{json}{author} = $author;
        }
        else {
            $c->stash->{author} = $author;
        }
        return;
    }

    my $data = $author;

    my @form_errors;

    for my $font ( 'body_font_family', 'syntax_font_family', ) {
        $data->{theme}->{fonts}->{$font} = $req->params->{$font};
    }

    for my $font (
        'body_font_size', 'input_font_size',
        'h1_font_size',   'h2_font_size',
        'h3_font_size',   'h4_font_size',
        'h5_font_size',   'h6_font_size'
        )
    {
        my $val = $req->params->{$font};
        if ( $val !~ m/^(\d+)$/ ) {
            push @form_errors,
                {
                field   => $font,
                message => "$font is not an integer.",
                };
            next;
        }
        $data->{theme}->{fonts}->{$font} = $req->params->{$font};
    }

    $data->{theme}->{dark_mode} = $req->params->{dark_mode} ? \1 : \0;

    for my $style (
        'main_background_color',
        'main_font_color',
        'main_second_font_color',
        'main_border_color',
        'main_box_shadow_color',
        'main_text_shadow_color',
        'main_hover_background_color',
        'secondary_background_color',
        'secondary_font_color',
        'nav_background_color',
        'nav_border_color',
        'nav_font_color',
        'nav_selected_color',
        'nav_selected_font_color',
        'nav_selected_border_color',
        'nav_selected_box_shadow_color',
        'nav_hover_background_color',
        'nav_hover_font_color',
        'nav_hover_border_color',
        'nav_side_selected_color',
        'nav_side_selected_font_color',
        'nav_side_hover_background_color',
        'input_background_color',
        'input_font_color',
        'input_border_color',
        'input_focus_border_color',
        'input_focus_box_shadow_color',
        'btn_background_color',
        'btn_secondary_background_color',
        'btn_third_background_color',
        'btn_font_color',
        'btn_border_color',
        'btn_hover_background_color',
        'link_font_color',
        'link_hover_font_color',
        'syntax_keyword_color',
        'syntax_plain_color',
        'syntax_functions_color',
        'syntax_string_color',
        'syntax_comments_color',
        'syntax_variable_color',
        'syntax_border_color',
        'syntax_line_number_color',
        'syntax_hover_line_number_color',
        'syntax_selected_line_background_color',
        'activity_background_color',
        'primary_background_color',
        'primary_font_color',
        'primary_border_color',
        'primary_hover_background_color',
        'primary_hover_font_color',
        'primary_hover_border_color',
        'warning_background_color',
        'warning_font_color',
        'warning_border_color',
        'warning_hover_background_color',
        'warning_hover_font_color',
        'warning_hover_border_color',
        'success_background_color',
        'success_font_color',
        'success_border_color',
        'success_hover_background_color',
        'success_hover_font_color',
        'success_hover_border_color',
        'danger_background_color',
        'danger_font_color',
        'danger_border_color',
        'danger_hover_background_color',
        'danger_hover_font_color',
        'danger_hover_border_color',
        'info_background_color',
        'info_font_color',
        'info_border_color',
        'info_hover_background_color',
        'info_hover_font_color',
        'info_hover_border_color',
        'alert_success_background_color',
        'alert_success_font_color',
        'alert_success_border_color',
        'alert_success_link_color',
        'alert_warning_background_color',
        'alert_warning_font_color',
        'alert_warning_border_color',
        'alert_warning_link_color',
        'alert_info_background_color',
        'alert_info_font_color',
        'alert_info_border_color',
        'alert_info_link_color',
        'alert_danger_background_color',
        'alert_danger_font_color',
        'alert_danger_border_color',
        'alert_danger_link_color'
        )
    {
        # TODO add validation using Colouring::In
        my $color = Colouring::In->validate( $req->params->{$style} );
        if ( !$color->{valid} ) {
            push @form_errors,
                {
                field   => $style,
                message => $color->{color} . " is not a valid color.",
                };
            next;
        }
        $data->{theme}->{color_scheme}->{$style} = $req->params->{$style}
            if $req->params->{$style};
    }

    if (@form_errors) {
        $c->stash( { author => $data, errors => \@form_errors } );
        return;
    }

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
