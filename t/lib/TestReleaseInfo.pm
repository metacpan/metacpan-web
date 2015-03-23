use strict;
use warnings;

package #
  TestReleaseInfo;

use Moose;
use Class::MOP;
use Class::MOP::Class;
with qw(MetaCPAN::Web::Role::ReleaseInfo);

# I hate this.
has _context => (
    is => 'ro',
    default => sub {
        Class::MOP::Class->create_anon_class(
            methods => {
                uri_for_action => sub {
                    my ( $self, $uri, $args ) = @_;
                    $args ||= [];
                    if ( $uri eq '/author/index' ) {
                        return join q[/], q[], 'author', @$args;
                    }
                    else {
                        die "unmocked uri: $uri";
                    }
                }
            },
        )->new_object;
    }
);

__PACKAGE__->meta->make_immutable;
1;
