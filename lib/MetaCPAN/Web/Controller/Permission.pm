package MetaCPAN::Web::Controller::Permission;

use Moose;
use List::Util qw( uniq );
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub author : Chained('/author/root') : PathPart('permissions') Args(0) {
    my ( $self, $c ) = @_;

    my $pause_id = $c->stash->{pauseid};

    my $perms = $c->model('API::Permission')->by_author($pause_id)->get;
    $c->stash( {
        %$perms, search_term => $pause_id,
    } );
    $c->forward('view');
}

sub distribution : Chained('/dist/root') : PathPart('permissions') Args(0) {
    my ( $self, $c ) = @_;
    my $distribution = $c->stash->{distribution_name};

    my $perms = $c->model('API::Permission')->by_dist($distribution)->get;

    my $modules       = $perms->{permissions} || [];
    my $total_modules = @$modules;
    my %num_modules_of;
    for my $module (@$modules) {
        ++$num_modules_of{$_}
            for $module->{owner} // (), @{ $module->{co_maintainers} };
    }
    my @releaser = sort grep { $num_modules_of{$_} == $total_modules }
        keys %num_modules_of;

    $c->stash( {
        %$perms,
        releaser    => \@releaser,
        search_term => $distribution,
    } );
    $c->forward('view');
}

sub module : Chained('/module/root') : PathPart('permissions') Args(0) {
    my ( $self, $c ) = @_;
    my $module = $c->stash->{module_name};

    my $perms = $c->model('API::Permission')->by_module($module)->get;
    $c->stash( {
        %$perms, search_term => $module,
    } );
    $c->forward('view');
}

sub view : Private {
    my ( $self, $c ) = @_;
    my $perms = $c->stash->{permissions};

    if ( !( $perms && @$perms ) ) {
        $c->stash( {
            message => 'Permissions not found for '
                . $c->stash->{search_term},
        } );
        $c->detach('/not_found');
    }

    $c->stash( {
        owner_count   => scalar( uniq map $_->{owner}, @$perms ),
        comaint_count =>
            scalar( uniq map @{ $_->{co_maintainers} }, @$perms ),
    } );
}

__PACKAGE__->meta->make_immutable;

1;
