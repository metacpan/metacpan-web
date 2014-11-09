package MetaCPAN::Web::Role::Request;

use Moose::Role;
use Plack::Session;

use MetaCPAN::Web::Types qw( PositiveInt );

sub page {
    my $page = shift->parameters->{p};
    return $page && $page =~ /^\d+$/ ? $page : 1;
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

1;
