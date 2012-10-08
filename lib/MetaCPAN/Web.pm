package MetaCPAN::Web;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90011;
use CatalystX::RoleApplicator;

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Unicode::Encoding
    Authentication
    /;

extends 'Catalyst';

__PACKAGE__->apply_request_class_roles(qw(
    MetaCPAN::Web::Role::Request
    Catalyst::TraitFor::Request::REST::ForBrowsers
));

__PACKAGE__->apply_response_class_roles(qw(
    MetaCPAN::Web::Role::Response
));

__PACKAGE__->config(
    name                                        => 'MetaCPAN::Web',
    disable_component_resolution_regex_fallback => 1,
    encoding                                    => 'UTF-8',
    'Plugin::Authentication' => {
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

__PACKAGE__->setup();

1;
