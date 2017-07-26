package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Changes::Parser;
use Try::Tiny;
use Ref::Util qw(is_arrayref);

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( q{/}, @path ) );
}

sub release_changes {
    my ( $self, $path, %opts ) = @_;
    $path = join '/', @$path
        if is_arrayref($path);
    $self->get($path)->transform(
        done => sub {
            my $file    = shift;
            my $content = $file->{content}
                or return [];

            my $version
                = _parse_version( $opts{version} || $file->{version} );

            my @releases = _releases($content);

            my @changelogs;
            while ( my $r = shift @releases ) {
                if ( $r->{version_parsed} eq $version ) {
                    $r->{current} = 1;
                    push @changelogs, $r;
                    if ( $opts{include_dev} ) {
                        for my $dev_r (@releases) {
                            last
                                if !$dev_r->{dev};
                            push @changelogs, $dev_r;
                        }
                    }
                }
            }
            return \@changelogs;
        }
    );
}

sub _releases {
    my ($content) = @_;
    my $changelog
        = MetaCPAN::Web::Model::API::Changes::Parser->parse($content);

    my @releases = sort { $b->{version_parsed} cmp $a->{version_parsed} }
        map {
        my $v     = _parse_version( $_->{version} );
        my $trial = $_->{version} =~ /-TRIAL$/
            || $_->{note} && $_->{note} =~ /\bTRIAL\b/;
        my $dev = $trial || $_->{version} =~ /_/;
        +{
            %$_,
            version_parsed => $v,
            trial          => $trial,
            dev            => $dev,
        };
        } @{ $changelog->{releases} || [] };
    return @releases;
}

sub _parse_version {
    my ($v) = @_;
    $v =~ s/-TRIAL$//;
    $v =~ s/_//g;
    eval { $v = version->parse($v) };
    return $v;
}

__PACKAGE__->meta->make_immutable;

1;
