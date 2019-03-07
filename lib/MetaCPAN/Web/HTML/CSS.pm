package MetaCPAN::Web::HTML::CSS;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(style_parse filter_style style_gen);

my $escape_re = qr{
    \\[0-9a-fA-F]{1,6}
|
    \\[^\n0-9a-fA-F]
}x;

my $string_re = qr{
    "
    (?:
        [^"\\\n]+
    |
        $escape_re
    |
        \\\n
    )*
    "
|
    '
    (?:
        [^'\\\n]+
    |
        $escape_re
    |
        \\\n
    )*
    '
}x;

my $url_re = qr{
    url\(\s*
    (?:
        [^'"()\\\s\x00-\x20\x7f]
    |
        $string_re
    )
}x;

my $value_re = qr{
    (?:
        [^;]
    |
        $string_re
    )+
}x;

my $color_re = qr{
(?<color>
    [a-zA-Z]+
|
    \#[0-9a-zA-Z]{1,6}
|
    rgb\(\s*[0-9]+\s*,\s*[0-9]+\s*,\s*[0-9]+\s*\)
|
    rgba\(\s*[0-9]+\s*,\s*[0-9]+\s*,\s*[0-9]+\s*,\s*[0-9]+\s*\)
)
}x;

my $unit_re = qr{
(?<unit>
        [+-]?[0-9]+(?:\.[0-9]+)?(?i:e[+-][0-9]+)?
        (?:ch|em|ex|rem|vh|vw|vmin|vmax|px|cm|mm|in|pc|pt|%)
|
        0
)
}x;

my %unit_factor = (
    px  => 1,
    cm  => 96/2.54,
    mm  => 96/2.54/10,
    in  => 96,
    pc  => 16,
    pt  => 4/3,

    # estimate based on common font sizes, close enough for our purposes
    ch  => 8,
    em  => 14.3,
    ex  => 7.5,
    rem => 10,

);

sub map_units {
    my $in = shift;
    my ($unit) = $in =~ s/([a-z]+)$//;
    $in *= 1;

    return 0
        if $in == 0;

    if (my $factor = $unit_factor{$unit}) {
        return $in * $factor;
    }

    return undef;
}

my ($border_style_re) = map qr{$_}, join('|', qw(
    none
    hidden
    dotted
    dashed
    solid
    double
    groove
    ridge
    inset
    outset
));

my $border_element_re = qr{
    $color_re
|
    $unit_re
|
    $border_style_re
}x;

my ($white_space_re) = map qr{$_}, join('|', qw(
    normal
    nowrap
    pre
    pre-wrap
    pre-line
));

my $units_re = qr/$unit_re(?:\s+$unit_re){0,3}/;

my %filter = (
    'color'             => $color_re,
    'background'        => $color_re,
    'background-color'  => $color_re,
    'border'            => qr{$border_element_re(?:\s+$border_element_re)*},
    'border-top-style'  => $border_style_re,
    'border-top-width'  => $unit_re,
    'border-top-color'  => $color_re,
    'border-radius'     => qr{$units_re(?:\s+/\s+$units_re)?},
    'white-space'       => $white_space_re,
);

for my $sub (qw(style width color)) {
    my $re = $filter{"border-top-$sub"};
    $filter{"border-$sub"} = qr{$re(?:\s+$re){0,3}};
    $filter{"border-$_-$sub"} = $re
        for qw(right bottom left);
}

for my $filter (qw(padding margin)) {
    $filter{$filter} = $units_re;
    $filter{"$filter-$_"} = $unit_re
        for qw(top right bottom left);
}

sub filters {
    return { %filters };
}

sub style_parse {
    my ($style) = @_;
    my @rules;
    while ($style =~ m{
        (?:\G|;)\s*
        ([\w._-]+)\s*:\s*
        ($value_re)
        \s*(?:;|\z)
    }xg) {
        push @rules, [ $1, $2 ];
    }
    return \@rules;
}

sub style_gen {
    my ($rules) = @_;
    join '; ', map {
        my ($rule, @values) = @$_;
        $rule . ': ' . join ' ', @values;
    } @$rules;
}


sub filter_style {
    my ($style, $filters) = @_;
    $filters ||= \%filter;
    my $rules = style_parse($style);
    @$rules = grep {
        my ($rule, $value) = @$_;
        my $filter = $filters->{$rule};
        $filter && $value =~ /\A$filter\z/ && do {
            if (my $units = $-{unit}) {
                !grep $_ < 0, grep defined, map map_units($_), @$units;
            }
            else {
                1;
            }
        };
    } @$rules;
    return style_gen($rules);
}

1;
