use strict;
use warnings;

use Test::More;

{

    package ExtractFirstElement;
    use Moo;
    with('MetaCPAN::Web::Role::Adapter');
    1;
}

my $extractor = ExtractFirstElement->new;
my $test_data = [
    { language => ['perl'], country => ['cat'] },
    { language => [ 'haskell', 'perl' ], country => ['ind'] },
    { language => 'go', country => ['rus'] },
    { language => 'c',  country => 'can' },
];
my $expected_extraction = [
    {
        'language' => 'perl',
        'country'  => 'cat'
    },
    {
        'country'  => 'ind',
        'language' => 'haskell'
    },
    {
        'language' => 'go',
        'country'  => 'rus'
    },
    {
        'language' => 'c',
        'country'  => 'can'
    }
];
is_deeply $extractor->extract_first_element($test_data), $expected_extraction,
    'extract the first element from each array';

done_testing;
