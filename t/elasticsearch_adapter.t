use strict;
use warnings;

use Test::More;

{

    package    ## no critic (Package)
        ExtractSingleElement;
    use Moo;
    with('MetaCPAN::Web::Role::Elasticsearch::Adapter');
    1;
}

my $extractor = ExtractSingleElement->new;
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
is_deeply $extractor->single_valued_arrayref_to_scalar(
    $test_data, [ 'name', 'abstract' ]
    ),
    $expected_extraction,
    'flatten single element arrays when specified';

done_testing;
