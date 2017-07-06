package MetaCPAN::Web::Controller::Release;

use Moose;

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

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
    $c->stash( $c->model('API::Favorite')->find_plussers($dist)->get );
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
    my $out   = $data->get->{release};

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
    )->get;
    $self->stash_api_results( $c, $reqs, $out );
    $self->add_favorites_data( $out, $reqs->{favorites}, $out );

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

    $c->stash(
        $c->model('API::Favorite')->find_plussers($distribution)->get );

    my $categories = $self->_files_to_categories( map @{ $_->{files} },
        @{$reqs}{qw(files modules)} );

    my $changes
        = $c->model('API::Changes')->last_version( $reqs->{changes}, $out );

    # TODO: make took more automatic (to include all)
    $c->stash(
        template => 'release.html',
        release  => $out,

        %$categories,

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
    my $self = shift;
    my %files = map +( $_->{path} => $_ ), @_;

    my $ret = +{
        provides      => [],
        documentation => [],
        modules       => [],
        other         => [],
        examples      => [],
    };

    for my $path ( sort keys %files ) {
        my $f = $files{$path};
        next
            if $f->{skip};
        my $path = $f->{path};
        my @modules = @{ $f->{module} || [] };

        for my $module (@modules) {
            my $assoc = $module->{associated_pod}
                or next;
            $assoc =~ s{^\Q$f->{author}/$f->{release}/}{};
            next
                if $assoc eq $f->{path}
                || $assoc ne $f->{path} =~ s{\.pm$}{\.pod}r;

            my $assoc_file = $files{$assoc}
                or next;

            $f->{$_} ||= $assoc_file->{$_} for qw(
                abstract
                documentation
            );
            $assoc_file->{skip}++;
        }

        if (@modules) {
            my %s;
            if ( $f->{documentation} ) {
                push @{ $ret->{modules} }, $f;
                $s{ $f->{documentation} }++;
            }

            push @{ $ret->{provides} },
                grep !$s{ $_->{name} }++,
                map +{ %$f, %$_, }, @modules;
        }
        elsif ( $f->{documentation} && $path =~ m/\.pm$/ ) {
            push @{ $ret->{modules} }, $f;
        }
        elsif ( $f->{documentation} ) {
            push @{ $ret->{documentation} }, $f;
        }
        elsif ( $path =~ m{^(?:eg|ex|examples?|samples?)\b}i ) {
            push @{ $ret->{examples} }, $f;
        }
        elsif ( $path =~ m/\.pod$/ ) {
            push @{ $ret->{documentation} }, $f;
        }
        else {
            push @{ $ret->{other} }, $f;
        }
    }

    $ret->{provides}
        = [ sort { $a->{name} cmp $b->{name} || $a->{path} cmp $b->{path} }
            @{ $ret->{provides} } ];

    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;
