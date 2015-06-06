use strict;
use warnings;

package    # no_index
    TestContext;

use Catalyst::Test 'TestApp';

use parent 'Exporter';

our @EXPORT_OK = qw(
    get_context
);

sub get_context {
    return ( ctx_request('/foo_not_real.txt') )[1];
}

1;
