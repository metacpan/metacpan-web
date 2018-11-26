package MetaCPAN::Web::Test::HTML5::Element::SVG;
use strict;
use warnings;

use parent 'HTML::Element';

sub starttag_XML {
    my $self   = shift;
    my $is_svg = $self->{_tag} eq 'svg';
    local $self->{xmlns}         = "http://www.w3.org/2000/svg" if $is_svg;
    local $self->{'xmlns:xlink'} = "http://www.w3.org/1999/xlink"
        if $is_svg;

    return $self->SUPER::starttag_XML(@_);
}

1;
