package MetaCPAN::Web::Controller::Release;

use Moose;

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use List::Util ();

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
    my @view_files = map { single_valued_arrayref_to_scalar($_) }
        map +{
        %{ $_->{fields} },
        module => [
            ( exists $_->{_source} and $_->{_source}{module} )
            ? $_->{_source}{module}
            : ()
        ],
        },
        @{ $modules->{hits}->{hits} };

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

__PACKAGE__->meta->make_immutable;

1;
