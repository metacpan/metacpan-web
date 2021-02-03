use strict;
use warnings;

use Test::More;
use MetaCPAN::Web                         ();
use MetaCPAN::Web::Model::API::Permission ();
use MetaCPAN::Web::Test qw( override_api_response );
use Cpanel::JSON::XS qw( decode_json encode_json );

subtest 'notification_type' => sub {
    my @tests = (
        {
            params   => {},
            expected => undef,
            message  => 'empty hash of data passed'
        },
        {
            params => {
                co_maintainers => [ 'ONE', 'TWO', 'THREE' ]
            },
            expected => undef,
            message  =>
                'co_maintainers passed without "special" co_maintainer existing'
        },
        {
            params => {
                module_name    => 'Mod::Name',
                co_maintainers => [ 'ADOPTME', 'ONE', 'TWO', 'THREE' ]
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'ADOPTME',
                authors     => [ 'ONE', 'TWO', 'THREE', ],
                emails      => [
                    'modules@perl.org', 'one@example.com',
                    'two@example.com',  'three@example.com',
                ],
            },
            message => 'ADOPTME passed in co_maintainers'
        },
        {
            params => {
                module_name    => 'Mod::Name',
                co_maintainers => [ 'ONE', 'NEEDHELP', 'TWO', 'THREE' ]
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'NEEDHELP',
                authors     => [ 'ONE', 'TWO', 'THREE', ],
                emails      => [
                    'one@example.com', 'two@example.com',
                    'three@example.com',
                ],
            },
            message => 'NEEDHELP passed in co_maintainers'
        },
        {
            params => {
                module_name    => 'Mod::Name',
                owner          => 'LNATION',
                co_maintainers => [ 'ONE', 'TWO', 'THREE', 'HANDOFF' ]
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'HANDOFF',
                authors     => [ 'LNATION', 'ONE', 'TWO', 'THREE', ],
                emails      => [
                    'lnation@example.com', 'one@example.com',
                    'two@example.com',     'three@example.com',
                ],
            },
            message => 'HANDOFF passed in co_maintainers'
        },
        {
            params => {
                owner => ''
            },
            expected => undef,
            message  => 'Null string as owner',
        },
        {
            params => {
                owner => undef
            },
            expected => undef,
            message  => 'Undef as owner'
        },
        {
            params => {
                owner => 'LNATION'
            },
            expected => undef,
            message  => 'LNATION as owner'
        },
        {
            params => {
                module_name => 'Mod::Name',
                owner       => 'ADOPTME'
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'ADOPTME',
                authors     => [],
                emails      => ['modules@perl.org'],
            },
            message => 'ADOPTME passed as owner'
        },
        {
            params => {
                module_name => 'Mod::Name',
                owner       => 'HANDOFF'
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'HANDOFF',
                authors     => [],
                emails      => ['modules@perl.org'],
            },
            message => 'HANDOFF passed as owner'
        },
        {
            params => {
                module_name => 'Mod::Name',
                owner       => 'NEEDHELP'
            },
            expected => {
                module_name => 'Mod::Name',
                type        => 'NEEDHELP',
                authors     => [],
                emails      => ['modules@perl.org'],
            },
            message => 'NEEDHELP passed as owner'
        },
    );

    my $api_data;
    override_api_response( sub {
        my ( undef, $req ) = @_;
        my $this_api_data;
        if ( $req->uri =~ m{/author/by_ids\b} ) {
            $this_api_data = {
                authors => [
                    map +( {
                        pauseid => $_,
                        email   => /one/i
                        ? [ lc($_) . '@example.com' ]
                        : lc($_) . '@example.com',
                    } ),
                    @{ decode_json( $req->content )->{id} }
                ]
            };
        }
        elsif ( $req->uri =~ m{/permission/by_module\b} ) {
            $this_api_data = { permissions => [ $api_data, ], };
        }
        else {
            die "unexpected API call";
        }
        return [
            200,
            [ "Content-Type" => "application/json" ],
            [ encode_json $this_api_data ],
        ];
    } );

    my $model = MetaCPAN::Web->model( 'API::Permission',
        api => 'http://example.com' );
    for my $test (@tests) {
        $api_data = $test->{params};
        my $notif = $model->get_notification_info( $api_data->{module_name} );
        is_deeply( $notif->get->{notification},
            $test->{expected}, $test->{message} );
    }
};

done_testing;
