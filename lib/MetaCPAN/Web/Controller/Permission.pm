package MetaCPAN::Web::Controller::Permission;

use Moose;
use List::Util qw(uniq);
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub author : Local Args(1) {
    my ( $self, $c, $pause_id ) = @_;

    $c->forward( 'get', $c, [ 'author', $pause_id ] );
}

sub distribution : Local Args(1) {
    my ( $self, $c, $distribution ) = @_;

    $c->forward( 'get', $c, [ 'distribution', $distribution ] );

    my $modules       = $c->stash->{permission};
    my $total_modules = scalar @$modules;
    my %num_modules_of;
    for my $module (@$modules) {
        ++$num_modules_of{ $module->{owner} };
        ++$num_modules_of{$_} for @{ $module->{co_maintainers} };
    }
    my @releaser = sort grep { $num_modules_of{$_} == $total_modules }
        keys %num_modules_of;

    $c->stash( releaser => \@releaser );
}

sub module : Local Args(1) {
    my ( $self, $c, $module ) = @_;

    $c->forward( 'get', $c, [ 'module', $module ] );
}

sub get : Private {
    my $self = shift;
    my $c    = shift;
    my ( $type, $name ) = @_;

    my $perms = $c->model('API::Permission')->get( $type, $name )->get;

    if ( !$perms ) {
        $c->stash( {
            message => 'Permissions not found for ' . $name
        } );
        $c->detach('/not_found');
    }

    $c->stash( { search_term => $name, permission => $perms } );

    return if $type eq 'module';
    $c->stash( {
        num_owners   => scalar( uniq map $_->{owner},               @$perms ),
        num_comaints => scalar( uniq map @{ $_->{co_maintainers} }, @$perms ),
    } );
}

__PACKAGE__->meta->make_immutable;

1;
