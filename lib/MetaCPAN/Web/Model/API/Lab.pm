package MetaCPAN::Web::Model::API::Lab;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API::File';

=head1 NAME

MetaCPAN::Web::Model::Lab - Catalyst Model

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub dependencies {
    my ( $self, $module ) = @_;

    my %deps;
    my @modules = ($module);
    my $max     = 20;          # limit the number of requests
    while (@modules) {
        last if $max-- <= 0;
        push @modules, $self->_handle_module( \%deps, shift @modules );
    }
    $deps{$module}{orig} = 1;

    return [
        map { $deps{$_} }
            reverse
            sort { $deps{$a}{date} cmp $deps{$b}{date} }
            keys %deps
    ];
}

my %CORE = map { $_ => 1 } qw(
    perl
    warnings
    strict
    FindBin
);

sub _handle_module {
    my ( $self, $dependencies, $module ) = @_;

    return if $CORE{$module};
    return if $dependencies->{$module};

    # special case
    if ( $module eq 'common::sense' ) {
        $dependencies->{$module} = 'common-sense';
        return;
    }

    # get the distribution that provides this module
    my $cv  = $self->cv;
    my $rm  = $self->request("/module/$module")->recv;
    my %dep = (
        dist => $rm->{distribution},
        date => $rm->{date},
    );

    my $cv2 = $self->cv;
    my $rd  = $self->request("/release/$rm->{distribution}")->recv;

    $dep{license} = $rd->{license};

    $dependencies->{$module} = \%dep;

    return map { $_->{module} } @{ $rd->{dependency} };
}

sub fetch_latest_distros {
    my ( $self, $size, $pauseid ) = @_;

    my @filter = ( { term => { status => 'latest' } } );
    if ($pauseid) {
        push @filter, { term => { author => $pauseid } };
    }

    my $cv = $self->cv;
    my $r  = $self->request(
        '/release/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => \@filter,
                    },
                },
            },
            sort => [ { date => 'desc' } ],
            fields =>
                [qw(distribution date license author resources.repository)],
            size => $size,
        },
    )->recv;

    #return $r;

    my %licenses;
    my @missing_licenses;
    my @missing_repo;
    my %repos;
    my $license_found = 0;
    my $repo_found    = 0;
    my $hits          = scalar @{ $r->{hits}{hits} };
    my %distros;

    foreach my $d ( @{ $r->{hits}{hits} } ) {
        my $license = $d->{fields}{license};
        my $distro  = $d->{fields}{distribution};
        my $author  = $d->{fields}{author};
        my $repo    = $d->{fields}{'resources.repository'};

# TODO: can we fetch the bug count and the test count in one call for all the distributions?
        my $distribution = $self->request("/distribution/$distro")->recv;
        if ( $distribution->{bugs} ) {
            $distros{$distro}{bugs} = $distribution->{bugs}{active};
        }

        my $release = $self->request("/release/$distro")->recv;
        $distros{$distro}{test} = $release->{tests};

        if (    $license
            and $license ne 'unknown'
            and $license ne 'open_source' )
        {
            $license_found++;
            $licenses{$license}++;
        }
        else {
            $distros{$distro}{license} = 1;
            push @missing_licenses,
                {
                name    => $distro,
                pauseid => $author,
                };
        }

        # See also root/inc/release-infro.html
        if ( $repo and ( $repo->{url} or $repo->{web} ) ) {
            $repo_found++;
        }
        else {
            $distros{$distro}{repo} = 1;
            push @missing_repo,
                {
                name    => $distro,
                pauseid => $author,
                };
        }
    }
    @missing_licenses = sort { $a->{name} cmp $b->{name} } @missing_licenses;
    @missing_repo     = sort { $a->{name} cmp $b->{name} } @missing_repo;
    return {
        total_asked_for  => $size,
        total_received   => $hits,
        license_found    => $license_found,
        missing_licenses => \@missing_licenses,
        repos_found      => $repo_found,
        missing_repos    => \@missing_repo,
        licenses         => \%licenses,
        distros          => \%distros,
    };
}

__PACKAGE__->meta->make_immutable;

1;

