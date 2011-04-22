package MetaCPAN::Web::Request;
use strict;
use warnings;
use base 'Plack::Request';

use Encode;
use URI::Escape;

my $CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC;

sub path {
    my $self = shift;
    ($self->{decoded_path}) =
        $self->_decode(URI::Escape::uri_unescape($self->uri->path))
        unless($self->{decoded_path});
    return $self->{decoded_path};
}

sub query_parameters {
    my $self = shift;
    $self->{decoded_query_params} ||= Hash::MultiValue->new(
        $self->_decode($self->uri->query_form)
    );
}

# XXX Consider replacing using env->{'plack.request.body'}?
sub body_parameters {
    my $self = shift;
    $self->{decoded_body_params} ||= Hash::MultiValue->new(
        $self->_decode($self->SUPER::body_parameters->flatten)
    );
}

sub _decode {
    my $enc = shift->headers->content_type_charset || 'UTF-8';
    map { decode $enc, $_, $CHECK } @_;
}

1;