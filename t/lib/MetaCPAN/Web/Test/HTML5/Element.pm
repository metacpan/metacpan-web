package MetaCPAN::Web::Test::HTML5::Element;
use strict;
use warnings;

use parent 'HTML::Element';

use MetaCPAN::Web::Test::HTML5::Element::SVG;
use constant SVG_CLASS => 'MetaCPAN::Web::Test::HTML5::Element::SVG';

sub insert_element {
    my ($self, $tag, @more) = @_;
    local $self->{_element_class} = SVG_CLASS
        if $tag eq 'svg';
    $self->SUPER::insert_element($tag, @more);
}

sub _valid_name {
    my ( $self, $attr ) = @_;
    # HTML::Element doesn't allow single character attributes, so fake them
    # being longer
    $attr .= 'a'
        if length($attr) == 1
    $self->SUPER::_valid_name($attr);
}

1;
