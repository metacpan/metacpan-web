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
        {   files    => $model->interesting_files( $author, $release ),
            modules  => $model->modules( $author, $release ),
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
        map { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    my @examples = (
        sort { $a->{path} cmp $b->{path} }
        grep { $_->{path} =~ m{\b(?:eg|ex|examples?)\b}i and not $_->{path} =~ m{^x?t/} }
        map { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    $c->res->last_modified( $out->{date} );

    $self->groom_contributors( $c, $out );


    # TODO: make took more automatic (to include all)
    $c->stash(
        {   template => 'release.html',
            release  => $out,
            total    => $modules->{hits}->{total},
            took     => List::Util::max(
                $modules->{took}, $files->{took},
                $reqs->{versions}->{took}
            ),
            root     => \@root_files,
            examples => \@examples,
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

# massage the x_contributors field into what we want
sub groom_contributors {
    my( $self, $c, $out ) = @_;
    
    return unless $out->{metadata}{x_contributors};

    # just in case a lonely contributor makes it as a scalar
    $out->{metadata}{x_contributors} = [ 
        $out->{metadata}{x_contributors}
    ] unless ref $out->{metadata}{x_contributors};

    my @contributors = map {
        s/<(.*)>//;
        { name => $_, email => $1 }
    } @{$out->{metadata}{x_contributors}};

    $out->{metadata}{x_contributors} = \@contributors;

    for my $contributor ( @{ $out->{metadata}{x_contributors} } ) {

        # heuristic to autofill pause accounts
        $contributor->{pauseid} = uc $1
            if !$contributor->{pauseid} 
            and $contributor->{email} =~ /^(.*)\@cpan.org/;

        next unless $contributor->{pauseid};

        $contributor->{url} = 
            $c->uri_for_action( '/author/index', [ $contributor->{pauseid} ] );
    }
}

1;
