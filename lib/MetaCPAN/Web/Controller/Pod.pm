package MetaCPAN::Web::Controller::Pod;

use HTML::Restrict;
use Moose;
use Try::Tiny;
use JSON::XS qw(decode_json);

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

my $perltv_data;
my $perltv_time;

sub root : Chained('/') PathPart('pod') CaptureArgs(0) {
}

# /pod/$name
sub find : Chained('root') PathPart('') Args(1) {
    my ( $self, $c, @path ) = @_;

    # TODO: Pass size param so we can disambiguate?
    $c->stash->{pod_file} = $c->model('API::Module')->find(@path)->recv;

    # TODO: Disambiguate if there's more than once match. #176

    $c->forward( 'view', [@path] );
}

# /pod/release/$AUTHOR/$release/@path
sub release : Chained('root') Local Args {
    my ( $self, $c, @path ) = @_;

    # force consistent casing in URLs
    if ( @path > 2 && $path[0] ne uc( $path[0] ) ) {
        $c->res->redirect(
            '/pod/release/' . join( '/', uc( shift @path ), @path ), 301 );
        $c->detach();
    }

    $c->stash->{pod_file} = $c->model('API::Module')->get(@path)->recv;
    $c->forward( 'view', [@path] );
}

# /pod/distribution/$name/@path
sub distribution : Chained('root') Local Args {
    my ( $self, $c, $dist, @path ) = @_;

# TODO: Could we do this with one query?
# filter => { path => join('/', @path), distribution => $dist, status => latest }

    # Get latest "author/release" of dist so we can use it to find the file.
    # TODO: Pass size param so we can disambiguate?
    my $release = try {
        $c->model('API::Release')->find($dist)->recv->{hits}{hits}->[0]
            ->{_source};
    } or $c->detach('/not_found');

    # TODO: Disambiguate if there's more than once match. #176

    unshift @path, @$release{qw( author name )};

    $c->stash->{pod_file} = $c->model('API::Module')->get(@path)->recv;

    $c->forward( 'view', [@path] );
}

sub view : Private {
    my ( $self, $c, @path ) = @_;

    my $data = $c->stash->{pod_file};

    if ( $data->{directory} ) {
        $c->res->redirect( '/source/' . join( '/', @path ), 301 );
        $c->detach;
    }

    my ( $documentation, $pod, $documented_module )
        = map { $_->{name}, $_->{associated_pod}, $_ }
        grep { @path > 1 || $path[0] eq $_->{name} }
        grep {
              !$data->{documentation}
            || $data->{documentation} eq $_->{name}
        }
        grep { $_->{associated_pod} } @{ $data->{module} || [] };
    $data->{documentation} = $documentation if $documentation;

    $c->detach('/not_found') unless ( $data->{name} );
    my $reqs = $self->api_requests(
        $c,
        {
            pod => $c->model('API')->request(
                '/pod/' . ( $pod || join( '/', @path ) ) . '?show_errors=1'
            ),
            release => $c->model('API::Release')
                ->get( @{$data}{qw(author release)} ),
        },
        $data,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results( $c, $reqs, $data );
    $self->add_favorites_data( $data, $reqs->{favorites}, $data );

    my $hr = HTML::Restrict->new;
    $hr->set_rules(
        {
            a       => [qw( href target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [],
            dd      => ['id'],
            div     => [qw(id style)],
            dl      => ['id'],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            img     => [qw( alt border height width src style title / )],
            li      => ['id'],
            ol      => [],
            p       => [qw(class style)],
            pre     => [qw(id class style)],
            span    => [qw(style)],
            strong  => [],
            sub     => [],
            sup     => [],
            table => [qw( style class border cellspacing cellpadding align )],
            tbody => [],
            td    => [qw(style class)],
            tr    => [qw(style class)],
            u     => [],
            ul    => ['id'],
        }
    );

    # ensure page is not cached when latest release is a trial
    $c->res->last_modified(
               $reqs->{versions}->{hits}->{hits}->[0]->{fields}->{date}
            || $data->{date} );

    my $release = $reqs->{release}->{hits}->{hits}->[0]->{_source};

    #<<<
    my $canonical = ( $documented_module
            && $documented_module->{authorized}
            && $documented_module->{indexed}
        ) ? "/pod/$documentation"
        : join('/', '', qw( pod distribution ), $release->{distribution},
            # Strip $author/$release from front of path.
            @path[ 2 .. $#path ]
        );
    #>>>

    my $dist = $release->{distribution};
    $c->stash( $c->model('API::Favorite')->find_plussers($dist) );

    # Cache the PerlTV json file in memory
    my $CACHE = 60 * 60;
    if ( not $perltv_time or $perltv_time < time - $CACHE ) {
        my $perltv_file = $c->config->{perltv_file};
        if ( open my $fh, '<', $perltv_file ) {
            local $/ = undef;
            my $json = <$fh>;
            close $fh;
            eval {
                $perltv_data = decode_json $json;
                $perltv_time = time;
            };
        }
    }
    if ($perltv_data) {
        my $ptv = $perltv_data->{modules}{ $data->{documentation} };
        if ($ptv) {

            # There can be more than one video per module. Show them randomly.
            $c->stash( { perltv => $ptv->[ int rand scalar @$ptv ] } );
        }
    }

    $c->stash(
        {
            module            => $data,
            pod               => $hr->process( $reqs->{pod}->{raw} ),
            release           => $release,
            template          => 'pod.html',
            canonical         => $canonical,
            documented_module => $documented_module,
        }
    );
    unless ( $reqs->{pod}->{raw} ) {
        $c->stash( pod_error => $reqs->{pod}->{message}, );
    }
}

1;
