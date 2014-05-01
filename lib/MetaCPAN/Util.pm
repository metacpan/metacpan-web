package MetaCPAN::Util;

use strict;
use warnings;

use ElasticSearch;
use Sub::Exporter -setup => { exports => ['es'] };

sub es {
    return ElasticSearch->new(
        no_refresh  => 1,
        servers     => 'api.metacpan.org',
        trace_calls => \*STDOUT,
        transport   => 'curl',
    );
}

1;
