package MetaCPAN::Web::View::Raw;

use strict;
use warnings;
use base 'MetaCPAN::Web::View::HTML';

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config
        = $self->merge_config_hashes( $app->config->{'View::HTML'}, $config );
    return $self->SUPER::COMPONENT( $app, $config );
}

1;
