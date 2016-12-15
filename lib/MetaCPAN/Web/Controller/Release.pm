package MetaCPAN::Web::Controller::Release;

use Moose;

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use List::Util ();
use Ref::Util qw( is_arrayref );

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

sub root : Chained('/') PathPart('release') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{model} = $c->model('API::Release');
}

sub by_distribution : Chained('root') PathPart('') Args(1) {
    my ( $self, $c, $distribution ) = @_;

    my $model = $c->stash->{model};
    $c->stash->{data} = $model->find($distribution);
    $c->forward('view');
}

sub index : Chained('/') PathPart('release') CaptureArgs(1) {
    my ( $self, $c, $dist ) = @_;
    $c->stash( $c->model('API::Favorite')->find_plussers($dist) );
}

sub plusser_display : Chained('index') PathPart('plussers') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( { template => 'plussers.html' } );
}

sub by_author_and_release : Chained('root') PathPart('') Args(2) {
    my ( $self, $c, $author, $release ) = @_;

    my $model = $c->stash->{model};

    # force consistent casing in URLs
    if ( $author ne uc($author) ) {
        $c->res->redirect(
            $c->uri_for_action(
                $c->controller->action_for('by_author_and_release'),
                [ uc($author), $release ]
            ),
            301
        );
        $c->detach();
    }

    $c->stash->{permalinks} = 1;
    $c->stash->{data} = $model->get( $author, $release );
    $c->forward('view');
}

sub view : Private {
    my ( $self, $c ) = @_;

    my $model = $c->stash->{model};
    my $data  = delete $c->stash->{data};
    my $out   = $data->recv->{hits}->{hits}->[0]->{_source};

    $c->detach('/not_found') unless ($out);

    my ( $author, $release, $distribution )
        = ( $out->{author}, $out->{name}, $out->{distribution} );

    my $reqs = $self->api_requests(
        $c,
        {
            files   => $model->interesting_files( $author,      $release ),
            modules => $model->modules( $author,                $release ),
            changes => $c->model('API::Changes')->get( $author, $release ),
        },
        $out,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results( $c, $reqs, $out );
    $self->add_favorites_data( $out, $reqs->{favorites}, $out );

    # shortcuts
    my ( $files, $modules ) = @{$reqs}{qw(files modules)};

    my @root_files = (
        sort { $a->{name} cmp $b->{name} }
        grep { $_->{path} !~ m{/} }
        map  { single_valued_arrayref_to_scalar($_) }
        map  { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    my @examples = (
        sort { $a->{path} cmp $b->{path} }
            grep {
            $_->{path} =~ m{\b(?:eg|ex|examples?|samples?)\b}i
                and not $_->{path} =~ m{^x?t/}
            }
            map { single_valued_arrayref_to_scalar($_) }
            map { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    $c->res->last_modified( $out->{date} );
    $c->cdn_max_age('1y');
    $c->add_dist_key($distribution);
    $c->add_author_key($author);

    $c->stash(
        $c->model(
            'ReleaseInfo',
            {
                author       => $reqs->{author},
                distribution => $reqs->{distribution},
                release      => $out
            }
        )->summary_hash
    );

    $c->stash( $c->model('API::Favorite')->find_plussers($distribution) );

    # Simplify the file data we pass to the template.
    my @view_files = map +{ %{ $_->{fields} }, %{ $_->{_source} }, },
        @{ $modules->{hits}->{hits} };

    my $categories = $self->_files_to_categories( $out, \@view_files );

    my $changes
        = $c->model('API::Changes')->last_version( $reqs->{changes}, $out );

    # TODO: make took more automatic (to include all)
    $c->stash(
        template => 'release.html',
        release  => $out,
        total    => $modules->{hits}->{total},
        took     => List::Util::max(
            $modules->{took}, $files->{took}, $reqs->{versions}->{took}
        ),
        root     => \@root_files,
        examples => \@examples,
        files    => \@view_files,

        documentation     => $categories->{documentation},
        documentation_raw => $categories->{documentation_raw},
        provides          => $categories->{provides},
        modules           => $categories->{modules},

        # TODO: Put this in a more general place.
        # Maybe make a hash for feature flags?
        (
            map { ( $_ => $c->config->{$_} ) }
                qw( mark_unauthorized_releases )
        ),

        (
            @$changes
            ? (
                last_version_changes => $changes->[0],
                changelogs           => $changes,
                )
            : ()
        )
    );
}

sub _files_to_categories {
    my ( $self, $release, $files ) = @_;
    my $ret = +{
        provides          => [],
        documentation     => [],
        documentation_raw => [],
        modules           => [],
    };

    my %skip;

    for my $f (@$files) {
        next if $f->{documentation};
        for my $module ( @{ $f->{module} || [] } ) {
            my $assoc = $module->{associated_pod} or next;
            $assoc =~ s{^\Q$f->{author}/$f->{release}/}{};
            if (   $assoc ne $f->{path}
                && $assoc eq $f->{path} =~ s{\.pm$}{\.pod}r )
            {
                my ($assoc_file) = grep $_->{path} eq $assoc, @$files;
                $f->{$_} ||= $assoc_file->{$_} for qw(
                    abstract
                    documentation
                );
                $skip{$assoc}++;
            }
        }
    }

    for my $f ( @{$files} ) {
        next
            if $skip{ $f->{path} };
        my %info = (
            status  => $f->{status},
            path    => $f->{path},
            release => $f->{release},
            author  => $f->{author},
        );

        my @modules = @{ $f->{module} || [] };

        if ( $f->{documentation} and @modules ) {
            push @{ $ret->{modules} }, $f;
            push @{ $ret->{provides} },
                map +{
                %info,
                package    => $_->{name},
                authorized => $_->{authorized}
                },
                grep {
                        defined $_->{name}
                    and $_->{name} ne $f->{documentation}
                    and $_->{indexed}
                    and $_->{authorized}
                } @modules;
        }
        elsif (@modules) {
            push @{ $ret->{provides} },
                map +{
                %info,
                package    => $_->{name},
                authorized => $_->{authorized}
                }, @modules;
        }
        elsif ( $f->{documentation} ) {
            push @{ $ret->{documentation} }, $f;
        }
        else {
            push @{ $ret->{documentation_raw} }, $f;
        }
    }

    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;

