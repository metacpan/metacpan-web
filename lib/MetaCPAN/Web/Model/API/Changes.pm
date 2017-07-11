package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Changes::Parser;
use Try::Tiny;

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( q{/}, @path ) );
}

sub last_version {
    my ( $self, $response, $release ) = @_;
    my $releases;
    if ( !exists $response->{content} or $response->{documentation} ) {
    }
    else {
        # I guess we have a propper changes file? :P
        try {
            my $changelog
                = MetaCPAN::Web::Model::API::Changes::Parser->parse(
                $response->{content} );
            $releases = $changelog->{releases};
        }
        catch {
            # we don't really care?
            warn "Error parsing changes: $_" if $ENV{CATALYST_DEBUG};
        };
    }
    return [] unless $releases && @$releases;

    my $version = $release->{version};
    eval { $version = version->parse($version) };

    my @releases = sort { $b->[0] <=> $a->[0] }
        map {
        my $v   = $_->{version} =~ s/-TRIAL$//r;
        my $dev = $_->{version} =~ /_|-TRIAL$/
            || $_->{note} && $_->{note} =~ /\bTRIAL\b/;
        my $ver = ( ref $version && length $v && eval { version->parse($v) } )
            || $v;
        [ $ver, $v, $dev, $_ ];
        } @$releases;

    my @changelogs;
    my $found;
    for my $r (@releases) {
        if ($found) {
            if ( $r->[2] ) {
                push @changelogs, $r->[3];
            }
            else {
                last;
            }
        }
        elsif ( $r->[0] eq $version ) {
            push @changelogs, $r->[3];
            $found = 1;
        }
    }
    return \@changelogs;
}

sub find_changelog {
    my ( $self, $version, $releases ) = @_;

    foreach my $rel (@$releases) {
        return $rel
            if ( $rel->{version} eq $version
            || $rel->{version} eq "$version-TRIAL" );
    }
}

__PACKAGE__->meta->make_immutable;

1;
