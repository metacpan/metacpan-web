package HTML5::Element::SVG;
use strict;
use warnings;

use parent 'HTML5::Element';

sub starttag_XML {
    my $self   = shift;

    local $self->{xmlns} = 'http://www.w3.org/2000/svg'
        if $self->{_tag} eq 'svg';
    my @ns = grep /^xmlns:/, keys %$self;
    local @{$self}{@ns};
    delete @{$self}{@ns};

    return $self->SUPER::starttag_XML(@_);
}

sub element_class {
    $_[0]->{_element_class} || __PACKAGE__;
}

1;
