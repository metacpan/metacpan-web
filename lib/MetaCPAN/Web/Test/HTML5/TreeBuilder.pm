package MetaCPAN::Web::Test::HTML5::TreeBuilder;
use strict;
use warnings;

use parent 'HTML::TreeBuilder';

use MetaCPAN::Web::Test::HTML5::Element::SVG;
use constant SVG_CLASS => 'MetaCPAN::Web::Test::HTML5::Element::SVG';

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

sub start {
    my $self = shift;
    my $e;
    my $pos = $self->{'_pos'} || $self;
    if ( !$pos->isa(SVG_CLASS) ) {
        local $HTML::TreeBuilder::isBodyElement{article}    = 1;
        local $HTML::TreeBuilder::isBodyElement{audio}      = 1;
        local $HTML::TreeBuilder::isBodyElement{aside}      = 1;
        local $HTML::TreeBuilder::isBodyElement{bdi}        = 1;
        local $HTML::TreeBuilder::isBodyElement{datalist}   = 1;
        local $HTML::TreeBuilder::isBodyElement{canvas}     = 1;
        local $HTML::TreeBuilder::isBodyElement{details}    = 1;
        local $HTML::TreeBuilder::isBodyElement{dialog}     = 1;
        local $HTML::TreeBuilder::isBodyElement{embed}      = 1;
        local $HTML::TreeBuilder::isBodyElement{figcaption} = 1;
        local $HTML::TreeBuilder::isBodyElement{figure}     = 1;
        local $HTML::TreeBuilder::isBodyElement{footer}     = 1;
        local $HTML::TreeBuilder::isBodyElement{header}     = 1;
        local $HTML::TreeBuilder::isBodyElement{main}       = 1;
        local $HTML::TreeBuilder::isBodyElement{mark}       = 1;
        local $HTML::TreeBuilder::isBodyElement{menuitem}   = 1;
        local $HTML::TreeBuilder::isBodyElement{meter}      = 1;
        local $HTML::TreeBuilder::isBodyElement{nav}        = 1;
        local $HTML::TreeBuilder::isBodyElement{output}     = 1;
        local $HTML::TreeBuilder::isBodyElement{progress}   = 1;
        local $HTML::TreeBuilder::isBodyElement{rp}         = 1;
        local $HTML::TreeBuilder::isBodyElement{rt}         = 1;
        local $HTML::TreeBuilder::isBodyElement{ruby}       = 1;
        local $HTML::TreeBuilder::isBodyElement{section}    = 1;
        local $HTML::TreeBuilder::isBodyElement{source}     = 1;
        local $HTML::TreeBuilder::isBodyElement{summary}    = 1;
        local $HTML::TreeBuilder::isBodyElement{svg}        = 1;
        local $HTML::TreeBuilder::isBodyElement{time}       = 1;
        local $HTML::TreeBuilder::isBodyElement{track}      = 1;
        local $HTML::TreeBuilder::isBodyElement{video}      = 1;
        local $HTML::TreeBuilder::isBodyElement{wbr}        = 1;
        $e = $self->SUPER::start(@_);

        if ( $e->tag eq 'svg' ) {
            bless $e, SVG_CLASS;
        }
    }
    else {
        local %HTML::TreeBuilder::isHeadElement       = ();
        local %HTML::TreeBuilder::isHeadOrBodyElement = ();
        local %HTML::TreeBuilder::isBodyElement       = map +( $_ => 1 ),
            @svg_elements;
        $e = $self->SUPER::start(@_);
        bless $e, SVG_CLASS;
    }
    return $e;
}

sub _valid_name {
    my ( $self, $attr ) = @_;
    $attr =~ s/^xlink://;
    return 1 if $attr =~ /\A[krxyz]\z/;
    $self->SUPER::_valid_name($attr);
}

1;
