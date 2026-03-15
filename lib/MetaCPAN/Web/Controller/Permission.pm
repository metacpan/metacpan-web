package MetaCPAN::Web::Controller::Permission;

use Moose;
use List::Util qw( uniq );
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub author : Chained('/author/root') : PathPart('permissions') Args(0) {
    my ( $self, $c ) = @_;

    my $pause_id = $c->stash->{pauseid};

    my $perms = $c->model('API::Permission')->by_author($pause_id)->get;

    my $modules = $perms->{permissions} || [];
    my $author_owns
        = scalar grep { defined $_->{owner} && $_->{owner} eq $pause_id }
        @$modules;

    $c->stash( {
        %$perms,
        search_term => $pause_id,
        author_owns => $author_owns,
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
    my %releaser_set;
    $releaser_set{$_} = 1
        for grep { $num_modules_of{$_} == $total_modules }
        keys %num_modules_of;

    # Split releasers into owners and co-maintainers
    my %is_owner;
    for my $module (@$modules) {
        $is_owner{ $module->{owner} } = 1 if defined $module->{owner};
    }
    my @releasers = sort keys %releaser_set;
    my @owners    = grep { $is_owner{$_} } @releasers;
    my @comaints  = grep { !$is_owner{$_} } @releasers;

    # Build flat module list with per-module non-releaser annotations
    my @module_list;
    my %has_perms_on;    # author => { module => 1 }
    for my $module (@$modules) {
        my @non_releasers
            = sort grep { !$releaser_set{$_} } @{ $module->{co_maintainers} };

        # Include owner if not a releaser
        if ( defined $module->{owner} && !$releaser_set{ $module->{owner} } )
        {
            unshift @non_releasers, $module->{owner};
        }
        push @module_list,
            {
            module_name   => $module->{module_name},
            non_releasers => \@non_releasers,
            };
        for my $author ( $module->{owner} // (),
            @{ $module->{co_maintainers} } )
        {
            $has_perms_on{$author}{ $module->{module_name} } = 1;
        }
    }
    @module_list
        = sort { $a->{module_name} cmp $b->{module_name} } @module_list;

    # For each non-releaser, find which modules they're missing
    my @all_module_names = map { $_->{module_name} } @module_list;
    my @permission_fixes;
    for my $author ( sort keys %has_perms_on ) {
        next if $releaser_set{$author};
        my @missing
            = grep { !$has_perms_on{$author}{$_} } @all_module_names;
        push @permission_fixes, { author => $author, missing => \@missing }
            if @missing;
    }

    $c->stash( {
        %$perms,
        comaints         => \@comaints,
        module_list      => \@module_list,
        owners           => \@owners,
        permission_fixes => \@permission_fixes,
        search_term      => $distribution,
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
