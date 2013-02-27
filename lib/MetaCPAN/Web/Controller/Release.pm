package MetaCPAN::Web::Controller::Release;

use Moose;
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

    $c->stash->{data} = $model->get( $author, $release );
    $c->forward('view');
}

sub view : Private {
    my ( $self, $c ) = @_;

    my $model = $c->stash->{model};
    my $data  = delete $c->stash->{data};
    my $out   = $data->recv->{hits}->{hits}->[0]->{_source};

    $c->detach('/not_found') unless ($out);

    my ( $author, $release ) = ( $out->{author}, $out->{name} );

    my $reqs = $self->api_requests(
        $c,
        {   root    => $model->root_files( $author, $release ),
            modules => $model->modules( $author,    $release ),
        },
        $out,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results( $c, $reqs, $out );
    $self->add_favorites_data( $out, $reqs->{favorites}, $out );

    # shortcuts
    my ( $root, $modules ) = @{$reqs}{qw(root modules)};

    my @root_files = (
        sort { $a->{name} cmp $b->{name} }
        map { $_->{fields} } @{ $root->{hits}->{hits} }
    );

    # TODO: add action for /changes/$release/$version ? that does this

    my ($changes) = grep { $_->{name} =~ m/\A(Change|NEWS)/i } @root_files;

    $c->res->last_modified( $out->{date} );

    if ( my $contributors = $out->{metadata}{x_contributors} ) {
        for my $contributor ( @$contributors  ) {
                # don't put email addresses on a web page
            next if $contributor =~ s/<.+?>//g;

            # looks like a cpan account?
            next unless $contributor =~ /^[A-Z]+$/;

            $contributor = {
                id  => $contributor,
                url => $c->uri_for_action( '/author/index', [ $contributor ] ),
            };
        }
    }

    # TODO: make took more automatic (to include all)
    $c->stash(
        {   template => 'release.html',
            release  => $out,
            changes  => $changes,
            total    => $modules->{hits}->{total},
            took     => List::Util::max(
                $modules->{took}, $root->{took},
                $reqs->{versions}->{took}
            ),
            root  => \@root_files,
            files => [
                map {
                    {
                        %{ $_->{fields} },
                            module   => $_->{fields}->{'_source.module'},
                            abstract => $_->{fields}->{'_source.abstract'}
                    }
                } @{ $modules->{hits}->{hits} }
            ]
        }
    );
}

1;
