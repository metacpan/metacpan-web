use strict;
use warnings;

use Test::More;

use MetaCPAN::Web::Elasticsearch::Adapter
    qw( single_valued_arrayref_to_scalar );

my $test_data = [
    {
        'name'     => 'MetaCPAN-Client',
        'provides' => [ 'MetaCPAN::Client', 'MetaCPAN::Client::Author', ],
        'abstract' =>
            'A comprehensive, DWIM-featured client to the MetaCPAN API',
    },
    {
        'name'     => ['MetaCPAN-Client'],
        'provides' => [ 'MetaCPAN::Client', 'MetaCPAN::Client::Author', ],
        'abstract' =>
            ['A comprehensive, DWIM-featured client to the MetaCPAN API'],
    },
    {
        'name'     => ['MetaCPAN-Client'],
        'provides' => [ 'MetaCPAN::Client', ],
        'abstract' =>
            ['A comprehensive, DWIM-featured client to the MetaCPAN API'],
    }

];

my $expected_extraction = [
    {
        'name'     => 'MetaCPAN-Client',
        'provides' => [ 'MetaCPAN::Client', 'MetaCPAN::Client::Author', ],
        'abstract' =>
            'A comprehensive, DWIM-featured client to the MetaCPAN API',
    },
    {
        'name'     => 'MetaCPAN-Client',
        'provides' => [ 'MetaCPAN::Client', 'MetaCPAN::Client::Author', ],
        'abstract' =>
            'A comprehensive, DWIM-featured client to the MetaCPAN API',
    },
    {
        'name'     => 'MetaCPAN-Client',
        'provides' => ['MetaCPAN::Client'],
        'abstract' =>
            'A comprehensive, DWIM-featured client to the MetaCPAN API',
    }

];

is_deeply single_valued_arrayref_to_scalar( $test_data,
    [ 'name', 'abstract' ] ),
    $expected_extraction,
    'flatten single element arrays when specified';

done_testing;
