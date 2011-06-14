package MetaCPAN::Web::Request;
use strict;
use warnings;
use base 'Plack::Request';

use URI::Query;
use Encode;
use URI::Escape;

my $CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC;

sub path {
    my $self = shift;
    ( $self->{decoded_path} )
        = $self->_decode( URI::Escape::uri_unescape( $self->uri->path ) )
        unless ( $self->{decoded_path} );
    return $self->{decoded_path};
}

sub query_parameters {
    my $self = shift;
    $self->{decoded_query_params}
        ||= Hash::MultiValue->new( $self->_decode( $self->uri->query_form ) );
}

# XXX Consider replacing using env->{'plack.request.body'}?
sub body_parameters {
    my $self = shift;
    $self->{decoded_body_params} ||= Hash::MultiValue->new(
        $self->_decode( $self->SUPER::body_parameters->flatten ) );
}

sub _decode {
    my $enc = shift->headers->content_type_charset || 'UTF-8';
    map { decode $enc, $_, $CHECK } @_;
}

=head query_string_with

 # QUERY_STRING is page=1&keyword=perl
 $request->query_string_with( page => 2, pretty => 1 );
 # return page=2&keyword=perl&pretty=1

=cut

sub query_string_with {
    my $self   = shift;
    my $params = shift;
    my $qq     = URI::Query->new( $self->parameters->flatten );
    $qq->replace(%$params);
    return $qq->stringify;
}

sub page {
    my $page = shift->parameters->{p};
    return $page && $page =~ /^\d+$/ ? $page : 1;
}

sub clone {
  my ($self, %extra) = @_;
  return (ref $self)->new({ %{$self->env}, %extra });
}

1;
