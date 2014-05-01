package MetaCPAN::Web::Controller::Release;

use MetaCPAN::API;
use Moose;

use feature qw( say );
use FindBin qw ($Bin);
use lib "$Bin/../lib";
use namespace::autoclean;

use MetaCPAN::Util qw( es );

binmode( STDOUT, ":utf8" );

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

    my $data = $c->stash->{data};
    my $out  = $data->recv->{hits}->{hits}->[0]->{_source};
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
        map  { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    my @examples = (
        sort { $a->{path} cmp $b->{path} }
            grep {
            $_->{path} =~ m{\b(?:eg|ex|examples?|samples?)\b}i
                and not $_->{path} =~ m{^x?t/}
            }
            map { $_->{fields} } @{ $files->{hits}->{hits} }
    );

    $c->res->last_modified( $out->{date} );

    $self->groom_contributors( $c, $out );

    #subroutine call to find plussers for the particular distribution.
    $self->find_plussers( $c, $distribution );

    # Simplify the file data we pass to the template.
    my @view_files;
    foreach my $hit ( @{ $modules->{hits}->{hits} } ) {
        my $f = $hit->{fields};
        my $h = {};
        while ( my ( $k, $v ) = each %$f ) {

            # Strip '_source.' prefix from keys.
            $k =~ s/^_source\.//;
            $h->{$k} = $v;
        }
        push @view_files, $h;
    }

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
        ( $changes ? ( last_version_changes => $changes ) : () )

    );
}

sub find_plussers {

    my ( $self, $c, $distribution ) = @_;

    #search for all users, match all according to the distribution.
    my $plusser = es()->search(
        index => 'v0',
        type  => 'favorite',
        size  => 1000,
        query => {
            filtered => {
                query  => { match_all => {} },
                filter => {
                    term => { 'favorite.distribution' => $distribution }
                },
            },
        },
        fields => ['user'],
    );

    #store in an array.
    my @plusser_users
        = map { $_->{fields}->{user} } @{ $plusser->{hits}->{hits} };
    my $total_plussers = @plusser_users;

    #search for users in plusser_users with pauseid.
    my $authors = es()->search(
        index => 'v0',
        type  => 'author',
        size  => scalar @plusser_users,
        query => {
            filtered => {
                query => { match_all => {} },
                filter => { terms => { 'author.user' => \@plusser_users } },
            },
        },
        fields => [ 'pauseid', 'name', 'gravatar_url' ],
        sort   => ['pauseid'],
    );

    #store them in another array.
    my @plusser_authors
        = map { $_->{fields}->{pauseid} } @{ $authors->{hits}->{hits} };
    my $total_authors = @plusser_authors;

    #find total non pauseid users who have ++ed the dist.
    my $total_nonauthors = ( $total_plussers - $total_authors );

    #store details of plussers with pause ids.
    my @plusser_details = map {
        {
            id   => $_->{fields}->{pauseid},
            pic  => $_->{fields}->{gravatar_url},
            name => $_->{fields}->{name}
        }
    } @{ $authors->{hits}->{hits} };

    #stash the data.
    $c->stash(
        plusser_authors => \@plusser_details,
        plusser_others  => $total_nonauthors
    );

}

# massage the x_contributors field into what we want
sub groom_contributors {
    my ( $self, $c, $out ) = @_;

    return unless $out->{metadata}{x_contributors};

    # just in case a lonely contributor makes it as a scalar
    $out->{metadata}{x_contributors} = [ $out->{metadata}{x_contributors} ]
        unless ref $out->{metadata}{x_contributors};

    my @contributors = map {
        s/<(.*)>//;
        { name => $_, email => $1 }
    } @{ $out->{metadata}{x_contributors} };

    $out->{metadata}{x_contributors} = \@contributors;

    for my $contributor ( @{ $out->{metadata}{x_contributors} } ) {

        # heuristic to autofill pause accounts
        $contributor->{pauseid} = uc $1
            if !$contributor->{pauseid}
            and $contributor->{email} =~ /^(.*)\@cpan.org/;

        next unless $contributor->{pauseid};

        $contributor->{url} = $c->uri_for_action( '/author/index',
            [ $contributor->{pauseid} ] );
    }
}

1;
