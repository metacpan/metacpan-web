package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use Future        ();
use Future::Utils qw( fmap_concat );
use Ref::Util     qw( is_arrayref );

use MetaCPAN::Web::Model::API::Changes::Parser ();

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( '/', @path ) );
}

sub _relevant_changes {
    my ( $self, $content, $opts ) = @_;

    my $version = _parse_version( $opts->{version} );

    my @releases = _releases($content);

    my @changelogs;

    if ( _versions_cmp( $releases[-1]->{version_parsed}, $version ) == 0 ) {
        @releases = reverse @releases;
    }
    elsif ( _versions_cmp( $releases[0]->{version_parsed}, $version ) == 0 ) {

        # noop
    }
    else {
        @releases = sort {
            _versions_cmp( $b->{version_parsed}, $a->{version_parsed} )
        } @releases;
        if ( _versions_cmp( $releases[0]->{version_parsed}, $version ) != 0 )
        {
            @releases = ();
        }
    }

    if (@releases) {
        my $current = shift @releases;
        $current->{current} = 1;
        push @changelogs, $current;

        if ( $opts->{include_dev} ) {
            for my $dev_r (@releases) {
                last
                    if !$dev_r->{dev};
                push @changelogs, $dev_r;
            }
        }
    }

    return \@changelogs;
}

sub release_changes {
    my ( $self, $path, %opts ) = @_;
    $path = join '/', @$path
        if is_arrayref($path);
    $self->get($path)->then( sub {
        my $file = shift;

        my $content = $file->{content}
            or return Future->done( { code => 404 } );

        $opts{version} ||= $file->{version};

        my $changes = $self->_relevant_changes( $content, \%opts );
        return Future->done( {
            changes => $changes,
        } );
    } );
}

sub by_releases {
    my ( $self, @releases ) = @_;

    fmap_concat(
        sub {
            my $batch = shift;
            $self->request(
                '/changes/by_releases',
                undef,
                {
                    release => $batch,
                }
            )->then( sub {
                my $response = shift;
                my @changes  = @{ $response->{changes} };

                my %changelogs;

                for my $change (@changes) {
                    $change->{release} =~ m/-(v?[0-9_\.]+(-TRIAL)?)\z/
                        or next;
                    my $version  = _parse_version($1);
                    my @releases = _releases( $change->{changes_text} );

                    for my $r (@releases) {
                        if ( _versions_cmp( $r->{version_parsed}, $version )
                            == 0 )
                        {
                            $r->{current} = 1;

                            $changelogs{
                                "$change->{author}/$change->{release}"} = $r;

                            last;
                        }
                    }
                }

                Future->done( \%changelogs );
            } );
        },
        generate => sub {
            my @batch = splice @releases, 0, 100;
            return @batch ? \@batch : ();
        },
        concurrent => 5,
    )->then( sub {
        return { map %$_, @_ };
    } );
}

sub _releases {
    my ($content) = @_;
    my $changelog
        = MetaCPAN::Web::Model::API::Changes::Parser->parse($content);

    my @releases = map {
        ;
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

sub _versions_cmp {
    my ( $v1, $v2 ) = @_;

    # we're comparing version objects
    if ( ref $v1 && ref $v2 ) {
        return $v1 cmp $v2;
    }

    # if one version failed to parse, force string comparison so version's
    # overloads don't try to inflate the other version
    else {
        return "$v1" cmp "$v2";
    }
}

sub _parse_version {
    my ($v) = @_;
    $v =~ s/-TRIAL$//;
    $v =~ s/_//g;
    $v =~ s/\A0+(\d)/$1/;
    use warnings FATAL => 'all';
    eval { $v = version->parse($v) };
    return $v;
}

__PACKAGE__->meta->make_immutable;

1;
