package MetaCPAN::Web::Controller;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

# For elasticsearch 1.x changes in the structure returned in the fields of {hits}{hits}
# See: http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_return_values.html
with('MetaCPAN::Web::Role::Adapter');

__PACKAGE__->meta->make_immutable;
