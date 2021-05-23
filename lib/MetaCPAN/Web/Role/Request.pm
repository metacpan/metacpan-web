package MetaCPAN::Web::Role::Request;

use Moose::Role;
use Plack::Session;
use Cpanel::JSON::XS ();
use MetaCPAN::Web::Types qw( is_PositiveInt );
use Try::Tiny qw( catch try );

use namespace::autoclean;

has final_args => ( is => 'rw' );

sub page {
    my $self = shift;
    my $page = $self->param('p');
    return is_PositiveInt($page) ? $page : 1;
}

sub session {
    my $self = shift;
    return Plack::Session->new( $self->env );
}

sub get_page_size {
    my $req               = shift;
    my $default_page_size = shift;

    my $page_size = $req->param('size');
    unless ( is_PositiveInt($page_size) && $page_size <= 500 ) {
        $page_size = $default_page_size;
    }
    return $page_size;
}

sub json_param {
    my ( $self, $name ) = @_;
    return try {
        Cpanel::JSON::XS->new->relaxed->utf8(
            $self->params_are_decoded ? 0 : 1 )
            ->decode( $self->params->{$name} );
    }
    catch {
        warn "Failed to decode JSON: $_[0]";
        undef;
    };
}

sub params_are_decoded {
    my ($self) = @_;
    return $self->params->{utf8} eq "\x{1f42a}";
}

1;
