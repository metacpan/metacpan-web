package MetaCPAN::Web::Model::API::Lab;
use Moose;
use namespace::autoclean;
use Future;

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

    return Future->done( [
        map { $deps{$_} }
            reverse
            sort { $deps{$a}{date} cmp $deps{$b}{date} }
            keys %deps
    ] );
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
    my $rm  = $self->request("/module/$module")->get;
    my %dep = (
        dist => $rm->{distribution},
        date => $rm->{date},
    );

    my $rd = $self->request("/release/$rm->{distribution}")->get;

    $dep{license} = $rd->{license};

    $dependencies->{$module} = \%dep;

    return map { $_->{module} } @{ $rd->{dependency} };
}

sub fetch_latest_distros {
    my ( $self, $size, $pauseid ) = @_;

    $self->request( "/release/by_author/$pauseid", undef, { size => $size } )
        ->transform(
        done => sub {
            my $data = shift;
            my %licenses;
            my %distros;

            foreach my $d ( @{ $data->{releases} } ) {
                my $license = $d->{license};
                my $distro  = $d->{distribution};
                my $repo    = $d->{'resources.repository'};

                next if $distros{$distro};    # show the first one

     # TODO: can we fetch the bug count in one call for all the distributions?
                my $distribution
                    = $self->request("/distribution/$distro")->get;
                if ( $distribution->{bugs} ) {
                    $distros{$distro}{bugs} = $distribution->{bugs}{active};
                }

                $distros{$distro}{test} = $d->{tests};
                my $total = 0;
                $total += ( $distros{$distro}{test}{$_} // 0 )
                    for qw(pass fail na);
                $distros{$distro}{test}{ratio}
                    = $total
                    ? int(
                    100 * ( $distros{$distro}{test}{pass} // 0 ) / $total )
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
                    = $d->{authorized} eq 'false' ? 1 : 0;

                # See also root/inc/release-infro.html
                if ( $repo and ( $repo->{url} or $repo->{web} ) ) {

                    # TODO: shall we collect the types and list them?
                }
                else {
                    $distros{$distro}{repo} = 1;
                }
                if ( not $d->{abstract} ) {
                    $distros{$distro}{abstract} = 1;
                }

                ( $distros{$distro}{date} = $d->{date} ) =~ s/\.\d+Z$//;
                $distros{$distro}{version}
                    = $d->{'metadata.version'};
            }

            return {
                licenses => \%licenses,
                distros  => \%distros,
            };
        }
        );
}

__PACKAGE__->meta->make_immutable;

1;
