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

# status can have all kinds of values, cpan is an attempt to find the ones that are on cpan but
# are not authorized. Maybe it also includes ones that were superseeded by releases of other people
    my @filter = (
        {
            or => [
                { term => { status => 'latest' } },
                { term => { status => 'cpan' } }
            ]
        }
    );
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
            sort => [
                'distribution', { 'version_numified' => { reverse => \1 } }
            ],
            fields => [
                qw(distribution date license author resources.repository abstract metadata.version tests status authorized)
            ],
            size => $size,
        },
    )->recv;
    my %licenses;
    my %distros;

    foreach my $d ( @{ $r->{hits}{hits} } ) {
        my $license = $d->{fields}{license};
        my $distro  = $d->{fields}{distribution};
        my $author  = $d->{fields}{author};
        my $repo    = $d->{fields}{'resources.repository'};

        next if $distros{$distro};    # show the firs one

     # TODO: can we fetch the bug count in one call for all the distributions?
        my $distribution = $self->request("/distribution/$distro")->recv;
        if ( $distribution->{bugs} ) {
            $distros{$distro}{bugs} = $distribution->{bugs}{active};
        }

        $distros{$distro}{test} = $d->{fields}{tests};
        my $total = 0;
        $total += ( $distros{$distro}{test}{$_} // 0 ) for qw(pass fail na);
        $distros{$distro}{test}{ratio}
            = $total
            ? int( 100 * ( $distros{$distro}{test}{pass} // 0 ) / $total )
            : q{};

        if (    $license
            and $license ne 'unknown'
            and $license ne 'open_source' )
        {
            $licenses{$license}++;
        }
        else {
            $distros{$distro}{license} = 1;
        }

        $distros{$distro}{unauthorized}
            = $d->{fields}{authorized} eq 'false' ? 1 : 0;

        # See also root/inc/release-infro.html
        if ( $repo and ( $repo->{url} or $repo->{web} ) ) {

            # TODO: shall we collect the types and list them?
        }
        else {
            $distros{$distro}{repo} = 1;
        }
        if ( not $d->{fields}{abstract} ) {
            $distros{$distro}{abstract} = 1;
        }

        ( $distros{$distro}{date} = $d->{fields}{date} ) =~ s/\.\d+Z$//;
        $distros{$distro}{version} = $d->{fields}{'metadata.version'};
    }
    return {
        licenses => \%licenses,
        distros  => \%distros,
    };
}

__PACKAGE__->meta->make_immutable;

1;

