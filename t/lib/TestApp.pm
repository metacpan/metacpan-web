use strict;
use warnings;

package    # no_index
    TestApp;

use Moose;
extends 'MetaCPAN::Web';

__PACKAGE__->setup_injected_component(
    'HTML' => { from_component => 'MetaCPAN::Web::View::HTML' } );

# If token returns a value the root controller will attempt to authenticate
# and then Plack::Session will error because something is missing. :-/
sub token {
    return;
}

__PACKAGE__->meta->make_immutable;

1;
