use strict;
use warnings;

use Test::More;
use aliased 'CPAN::Changes::Release';

use aliased 'MetaCPAN::Web::Model::API::Changes';

subtest 'find changelog' => sub {
    my $releases = [ Release->new( version => 0.01 ),
        Release->new( version => 12314 ), ];

    my $latest = Changes->find_changelog( 0.01, $releases );
    is( $latest->version, '0.01', 'found the version we wanted..' );

};

done_testing;
