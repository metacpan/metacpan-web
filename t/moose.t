use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Find      ();    # core
use Module::Runtime ();

sub uses_moose_ok {
    my ($mod) = @_;
SKIP: {
        my $meta      = $mod->can('meta') && $mod->meta;
        my $metaclass = $meta             && ref $meta;

        if ( $metaclass && $metaclass->can('is_immutable') ) {
            ::ok( $meta->is_immutable, "$mod is immutable" );
        }
        elsif ( $metaclass && $metaclass->isa('Moose::Meta::Role') ) {
            ::pass("$mod is a role");
        }
        else {
            ::skip( "$mod is not a Moose class or role", 1 );
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
