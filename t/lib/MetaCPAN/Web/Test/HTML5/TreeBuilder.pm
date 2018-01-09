package MetaCPAN::Web::Test::HTML5::TreeBuilder;
use strict;
use warnings;

use parent 'HTML::TreeBuilder';

use MetaCPAN::Web::Test::HTML5::Element::SVG ();    ## no perlimports

use constant SVG_CLASS => 'MetaCPAN::Web::Test::HTML5::Element::SVG';

use MetaCPAN::Web::Test::HTML5::Element::MathML;
use constant MATHML_CLASS => 'MetaCPAN::Web::Test::HTML5::Element::MathML';

my @html5_elements = qw(
    article audio aside bdi datalist canvas details dialog embed figcaption
    figure footer header main mark menuitem meter nav output progress rp rt
    ruby section source summary svg time track video wbr
);

my @svg_elements = qw(
    a altGlyph altGlyphDef altGlyphItem animate animateColor animateMotion
    animateTransform audio canvas circle clipPath color-profile cursor defs desc
    discard ellipse feBlend feColorMatrix feComponentTransfer feComposite
    feConvolveMatrix feDiffuseLighting feDisplacementMap feDistantLight
    feDropShadow feFlood feFuncA feFuncB feFuncG feFuncR feGaussianBlur feImage
    feMerge feMergeNode feMorphology feOffset fePointLight feSpecularLighting
    feSpotLight feTile feTurbulence filter font-face-format font-face-name
    font-face-src font-face-uri font-face font foreignObject g glyph glyphRef
    hatch hatchpath hkern iframe image line linearGradient marker mask mesh
    meshgradient meshpatch meshrow metadata missing-glyph mpath path pattern
    polygon polyline radialGradient rect script set solidcolor stop style svg
    switch symbol text textPath title tref tspan unknown use video view vkern
);

my @mathml_elements = qw(
    annotation-xml annotation maction maligngroup malignmark math menclose
    merror mfenced mfrac mglyph mi mlabeledtr mlongdiv mmultiscripts mn mo
    mover mpadded mphantom mroot mrow ms mscarries mscarry msgroup msline
    mspace msqrt msrow mstack mstyle msub msubsup msup mtable mtd mtext mtr
    munder munderover semantics
);

sub start {
    my $self = shift;
    my $e;
    my $pos = $self->pos;

    my $type = 'html';

    if ( $pos->isa(SVG_CLASS) ) {
        $type = 'svg';
    }
    elsif ( $pos->isa(MATHML_CLASS) ) {
        $type = 'mathml';
        if ( $pos->tag eq 'annotation-xml') {
            if (my $encoding = $pos->attr('encoding')) {
                if ($encoding eq 'SVG1.1' || $encoding eq 'image/svg+xml') {
                    $type = 'svg';
                }
                elsif ($encoding eq 'text/html') {
                    $type = 'html';
                }
            }
        }
    }

    local %HTML::TreeBuilder::isHeadElement
        = %HTML::TreeBuilder::isHeadElement;
    local %HTML::TreeBuilder::isHeadOrBodyElement
        = %HTML::TreeBuilder::isHeadOrBodyElement;
    local %HTML::TreeBuilder::isBodyElement
        = %HTML::TreeBuilder::isBodyElement,
            map +( $_ => 1 ), @html_elements;

    if ($type eq 'svg') {
        %HTML::TreeBuilder::isHeadElement       = ();
        %HTML::TreeBuilder::isHeadOrBodyElement = ();
        %HTML::TreeBuilder::isBodyElement       = map +( $_ => 1 ), @svg_elements;
    }
    elsif ($type eq 'mathml') {
        %HTML::TreeBuilder::isHeadElement       = ();
        %HTML::TreeBuilder::isHeadOrBodyElement = ();
        %HTML::TreeBuilder::isBodyElement       = map +( $_ => 1 ), @mathml_elements;
    }

    return $self->SUPER::start(@_);
}

1;
