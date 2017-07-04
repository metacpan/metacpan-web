package MetaCPAN::Web::Controller::Pod;

use HTML::Restrict;
use Moose;
use Try::Tiny;
use URI;
use HTML::Escape qw(escape_html);

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

# /pod/$name
sub find : Path : Args(1) {
    my ( $self, $c, @path ) = @_;

    $c->browser_max_age('1h');

    # TODO: Pass size param so we can disambiguate?
    $c->stash->{pod_file} = $c->model('API::Module')->find(@path)->get;

    # TODO: Disambiguate if there's more than once match. #176

    $c->forward( 'view', [@path] );
}

# /pod/release/$AUTHOR/$release/@path
sub release : Local : Args {
    my ( $self, $c, @path ) = @_;

    $c->browser_max_age('1d');

    # force consistent casing in URLs
    if ( @path > 2 && $path[0] ne uc( $path[0] ) ) {
        $c->res->redirect(
            '/pod/release/' . join( q{/}, uc( shift @path ), @path ), 301 );
        $c->detach();
    }

    $c->stash->{pod_file}   = $c->model('API::Module')->get(@path)->get;
    $c->stash->{permalinks} = 1;
    $c->forward( 'view', [@path] );
}

# /pod/distribution/$name/@path
sub distribution : Local : Args {
    my ( $self, $c, $dist, @path ) = @_;

    $c->browser_max_age('1h');

# TODO: Could we do this with one query?
# filter => { path => join('/', @path), distribution => $dist, status => latest }

    # Get latest "author/release" of dist so we can use it to find the file.
    # TODO: Pass size param so we can disambiguate?
    my $release = try {
        $c->model('API::Release')->find($dist)->get->{release};
    } or $c->detach('/not_found');

    # TODO: Disambiguate if there's more than once match. #176

    unshift @path, @$release{qw( author name )};

    $c->stash->{pod_file} = $c->model('API::Module')->get(@path)->get;

    $c->forward( 'view', [@path] );
}

sub view : Private {
    my ( $self, $c, @path ) = @_;

    my $data       = $c->stash->{pod_file};
    my $permalinks = $c->stash->{permalinks};

    if ( $data->{directory} ) {
        $c->res->redirect( '/source/' . join( q{/}, @path ), 301 );
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
    if ( $pod && $pod ne "$data->{author}/$data->{release}/$data->{path}" ) {
        $data->{pod_path}
            = $pod =~ s{^\Q$data->{author}/$data->{release}/}{}r;
    }

    $c->detach('/not_found') unless ( $data->{name} );

    my $pod_path = '/pod/' . ( $pod || join( q{/}, @path ) );

    my $reqs = $self->api_requests(
        $c,
        {
            pod => $c->model('API')->request(
                $pod_path,
                undef,
                {
                    show_errors => 1,
                    ( $permalinks ? ( permalinks => 1 ) : () ),
                    url_prefix => '/pod/',
                }
            ),
            release => $c->model('API::Release')
                ->get( @{$data}{qw(author release)} ),
        },
        $data,
    )->get;
    $self->stash_api_results( $c, $reqs, $data );
    $self->add_favorites_data( $data, $reqs->{favorites}, $data );

    my $hr = HTML::Restrict->new(
        uri_schemes =>
            [ undef, 'http', 'https', 'data', 'mailto', 'irc', 'ircs' ],
        rules => {
            a       => [qw( href id target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [ { class => qr/^language-\S+$/ } ],
            dd      => [],
            div     => [ { class => qr/^pod-errors(?:-detail)?$/ } ],
            dl      => [],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            li      => ['id'],
            ol      => [],
            p       => [],
            pre     => [
                {
                    class        => qr/^line-numbers$/,
                    'data-line'  => qr/^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$/,
                    'data-start' => qr/^\d+$/,
                }
            ],
            span   => [ { style => qr/^white-space: nowrap;$/ } ],
            strong => [],
            sub    => [],
            sup    => [],
            table => [ qw( border cellspacing cellpadding align ), ],
            tbody => [],
            th    => [],
            td    => [],
            tr    => [],
            u     => [],
            ul    => [ { id => qr/^index$/ } ],
        },
        replace_img => sub {

            # last arg is $text, which we don't need
            my ( $tagname, $attrs, undef ) = @_;
            my $tag = '<img';
            for my $attr (qw( alt border height width src title)) {
                next
                    unless exists $attrs->{$attr};
                my $val = $attrs->{$attr};
                if ( $attr eq 'src' ) {
                    if ( $val =~ m{^(?:(?:https?|ftp):)?//|^data:} ) {

                        # use directly
                    }
                    elsif ( $val =~ /^[0-9a-zA-Z.+-]+:/ ) {

                        # bad protocol
                        return '';
                    }
                    else {
                        my $base = "https://st.aticpan.org/source/";
                        if ( $val =~ s{^/}{} ) {
                            $base .= "$data->{author}/$data->{release}/";
                        }
                        else {
                            $base .= $pod
                                || "$data->{author}/$data->{release}/$data->{path}";
                        }
                        $val = URI->new_abs( $val, $base )->as_string;
                    }
                }
                $tag .= qq{ $attr="} . escape_html($val) . qq{"};
            }
            $tag .= ' />';
            return $tag;
        },
    );

    my $release = $reqs->{release}->{hits}->{hits}->[0]->{_source};

    #<<<
    my $canonical = ( $documented_module
            && $documented_module->{authorized}
            && $documented_module->{indexed}
        ) ? "/pod/$documentation"
        : join(q{/}, q{}, qw( pod distribution ), $release->{distribution},
            # Strip $author/$release from front of path.
            @path[ 2 .. $#path ]
        );
    #>>>

    my $dist = $release->{distribution};

    # Store at fastly for a year - as we will purge!
    $c->cdn_max_age('1y');
    $c->add_dist_key($dist);
    $c->add_author_key( $release->{author} );

    $c->stash( $c->model('API::Favorite')->find_plussers($dist)->get );

    $c->stash(
        $c->model(
            'ReleaseInfo',
            {
                author       => $reqs->{author},
                distribution => $reqs->{distribution},
                release      => $release,
            }
        )->summary_hash
    );

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

__PACKAGE__->meta->make_immutable;

1;
