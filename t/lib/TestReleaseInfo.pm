use strict;
use warnings;

package    #
    TestReleaseInfo;

use Moose;
use Class::MOP;
use Class::MOP::Class;
use Catalyst::Test 'TestApp';
use namespace::autoclean;

with qw(MetaCPAN::Web::Role::ReleaseInfo);

has _context => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        ( ctx_request('/robots.txt') )[1];
    },
);

__PACKAGE__->meta->make_immutable;
1;
