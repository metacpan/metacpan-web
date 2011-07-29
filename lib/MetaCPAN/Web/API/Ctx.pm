package MetaCPAN::Web::API::Ctx;

use Moose::Role;
use namespace::autoclean;

has ctx => (
    is       => 'ro',
    isa      => 'MetaCPAN::Web::API',
    weak_ref => 1,
);

1;
