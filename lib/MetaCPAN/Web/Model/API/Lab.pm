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
    my $max = 20; # limit the number of requests
    while (@modules) {
        last if $max-- <= 0;
        push @modules, $self->_handle_module(\%deps, shift @modules);
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
    my ($self, $dependencies, $module) = @_;

    return if $CORE{$module};
    return if $dependencies->{$module};

    # special case
    if ($module eq 'common::sense') {
        $dependencies->{$module} = 'common-sense';
        return;
    }

    # get the distribution that provides this module
    my $cv = $self->cv;
    my $rm = $self->request( "/module/$module" )->recv;
    my %dep = (
        dist => $rm->{distribution},
        date => $rm->{date},
    );
    

    my $cv2 = $self->cv;
    my $rd = $self->request( "/release/$rm->{distribution}" )->recv;

    $dep{license} = $rd->{license};

    $dependencies->{$module} = \%dep;

    return map { $_->{module} } @{ $rd->{dependency} };
}


__PACKAGE__->meta->make_immutable;

1;

