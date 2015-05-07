package MetaCPAN::Web::View::Raw;

use Moose;
extends 'MetaCPAN::Web::View::HTML';

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config
        = $self->merge_config_hashes( $app->config->{'View::HTML'}, $config );
    return $self->SUPER::COMPONENT( $app, $config );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
