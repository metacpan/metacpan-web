package MetaCPAN::Web;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90042;
use CatalystX::RoleApplicator;

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Authentication
    +MetaCPAN::Role::Fastly::Catalyst
    /, '-Log=warn,error,fatal';
use Log::Log4perl::Catalyst;

extends 'Catalyst';

__PACKAGE__->apply_request_class_roles( qw(
    MetaCPAN::Web::Role::Request
    Catalyst::TraitFor::Request::REST::ForBrowsers
) );

__PACKAGE__->apply_response_class_roles( qw(
    MetaCPAN::Web::Role::Response
) );

__PACKAGE__->config(
    name                                        => 'MetaCPAN::Web',
    disable_component_resolution_regex_fallback => 1,
    encoding                                    => 'UTF-8',
    'Plugin::Authentication'                    => {
        default => {
            credential => {
                class         => 'Password',
                password_type => 'none',
            },
            store => { class => 'Proxy', }
        },
    }
);

sub token {
    shift->request->session->get('token');
}

__PACKAGE__->log( Log::Log4perl::Catalyst->new( undef, autoflush => 1 ) );

# Squash warnings when not in a terminal (like when running under Docker)
# Catalyst throws warnings if it can't detect the size, even if $ENV{COLUMNS}
# exists. Just lie to it to shut it up.
use Term::Size::Perl;
if ( !Term::Size::Perl::chars() ) {
    no warnings 'once', 'redefine';
    *Term::Size::Perl::chars = sub { $ENV{COLUMNS} || 80 };
}

__PACKAGE__->setup;
__PACKAGE__->meta->make_immutable;

1;
