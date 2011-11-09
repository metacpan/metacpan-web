package MetaCPAN::Web::Controller::Release;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }
use List::Util ();

use JSON::XS   ();
use YAML::Tiny ();

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

sub index : PathPart('release') : Chained('/') : Args {
    my ( $self, $c, $author, $release ) = @_;
    my $model = $c->model('API::Release');

    # force consistent casing in URLs
    if ( $author && $release && $author ne uc($author) ) {
        $c->res->redirect("/release/" . uc($author) . "/$release", 301);
        $c->detach();
    }

    my $data
        = $author && $release
        ? $model->get( $author, $release )
        : $model->find($author);
    my $out = $data->recv->{hits}->{hits}->[0]->{_source};

    $c->detach('/not_found') unless ($out);

    ( $author, $release ) = ( $out->{author}, $out->{name} );

    my $reqs = $self->api_requests($c, {
            root    => $model->root_files( $author, $release ),
            modules => $model->modules(    $author, $release ),
        },
        $out,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results($c, $reqs, $out);
    $self->add_favorites_data($out, $reqs->{favorites}, $out);

    # shortcuts
    my ($root, $modules) = @{$reqs}{qw(root modules)};

    my @root_files = (
        sort
        map { $_->{fields}->{name} } @{ $root->{hits}->{hits} }
    );

    # TODO: add action for /changes/$release/$version ? that does this

    my $changes = undef;
    foreach my $filename ( @root_files ) {
        if ( $filename =~ m{\AChange}i || $filename eq 'NEWS' ) {
            $changes = $filename;
            last;
        }
    }

    my $meta = {};
    if (my ($filename) = grep { /^META/io } @root_files) {
        my $source = $c->model('API::Module')->source($author, $release, $filename)->recv;
        my $raw    = $source->{raw};

        if ($filename =~ /\.ya?ml$/) {
            $meta = eval { YAML::Tiny::Load($raw) };
        }
        elsif ($filename =~ /\.json$/) {
            $meta = eval { JSON::XS->new->utf8->decode($raw) };
        }
    }

    # TODO: make took more automatic (to include all)
    $c->stash(
        {   template => 'release.html',
            release  => $out,
            changes  => $changes,
            meta     => $meta,
            total    => $modules->{hits}->{total},
            took     => List::Util::max(
                $modules->{took}, $root->{took}, $reqs->{versions}->{took}
            ),
            root => \@root_files,
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
