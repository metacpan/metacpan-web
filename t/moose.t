use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Find ();        # core
use Module::Runtime ();

sub uses_moose_ok {
    my ($mod) = @_;
SKIP: {
        ::skip( "$mod is not a Moose class", 1 )
            unless $mod->can('meta');

        if ( $mod->meta->can('is_immutable') ) {
            ::ok( $mod->meta->is_immutable, "$mod is immutable" );
        }
        else {
            ::is(
                $mod->meta->attribute_metaclass,
                'Moose::Meta::Role::Attribute',
                "$mod is a role"
            );
        }
    }
}

sub package_from_path {
    local $_ = shift;
    s{^(t/)?lib/}{};
    s{\.pm$}{};
    s{[\\/]}{::}g;
    return $_;
}

my @modules;
File::Find::find(
    {
        no_chdir => 1,
        wanted   => sub {
            return unless /\.pm$/;
            push @modules, package_from_path($_);
        },
    },
    qw( lib t/lib ),
);

plan tests => scalar(@modules);

foreach my $mod (@modules) {
    Module::Runtime::require_module($mod);
    uses_moose_ok($mod);
}
