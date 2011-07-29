package MetaCPAN::Web::API::Result;

use strict;
use warnings;

sub fields {
    my ($self) = @_;
    return [ map { $_->{fields} } @{ $self->hits } ];
}

sub hits {
    my ($self) = @_;
    return $self->{hits}{hits} || [];
}

sub source {
    my ($self) = @_;
    return [ map { $_->{_source} } @{ $self->hits } ];
}

sub took {
    my ($self) = @_;
    return $self->{took};
}

sub total {
    my ($self) = @_;
    return $self->{hits}{total};
}

1;
