package MetaCPAN::Web::Model::API::Release;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::Util qw(first uniq);

=head1 NAME

MetaCPAN::Web::Model::Release - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Moritz Onken, Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub get {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/release/_search',
        {
            query => {
                bool => {
                    must => [
                        { term => { 'name' => $release } },
                        { term => { author => uc($author) } }
                    ]
                }
            }
        }
    );
}

sub distribution {
    my ( $self, $dist ) = @_;
    $self->request("/distribution/$dist");
}

sub latest_by_author {
    my ( $self, $pauseid ) = @_;
    $self->request("/release/latest_by_author/$pauseid");
}

sub all_by_author {
    my ( $self, $pauseid, $page, $page_size ) = @_;
    $self->request( "/release/all_by_author/$pauseid",
        undef, { page => $page, page_size => $page_size } );
}

sub recent {
    my ( $self, $page, $page_size, $type ) = @_;
    my $query;
    if ( $type eq 'n' ) {
        $query = {
            constant_score => {
                filter => {
                    bool => {
                        must => [
                            { term  => { first  => 1 } },
                            { terms => { status => [qw< cpan latest >] } },
                        ]
                    }
                }
            }
        };
    }
    elsif ( $type eq 'a' ) {
        $query = { match_all => {} };
    }
    else {
        $query = {
            constant_score => {
                filter => {
                    terms => { status => [qw< cpan latest >] }
                }
            }
        };
    }
    $self->request(
        '/release/_search',
        {
            size   => $page_size,
            from   => ( $page - 1 ) * $page_size,
            query  => $query,
            fields => [qw(name author status abstract date distribution)],
            sort   => [ { 'date' => { order => 'desc' } } ]
        }
    );
}

sub modules {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search',
        {
            query => {
                bool => {
                    must => [
                        { term => { release   => $release } },
                        { term => { author    => $author } },
                        { term => { directory => 0 } },
                        {
                            bool => {
                                should => [
                                    {
                                        bool => {
                                            must => [
                                                {
                                                    exists => {
                                                        field => 'module.name'
                                                    }
                                                },
                                                {
                                                    term => {
                                                        'module.indexed' => 1
                                                    }
                                                }
                                            ]
                                        }
                                    },
                                    {
                                        bool => {
                                            must => [
                                                {
                                                    range => {
                                                        slop => { gt => 0 }
                                                    }
                                                },
                                                {
                                                    exists => {
                                                        field =>
                                                            'pod.analyzed'
                                                    }
                                                },
                                                {
                                                    term => { 'indexed' => 1 }
                                                },
                                            ]
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            },
            size => 999,

            # Sort by documentation name; if there isn't one, sort by path.
            sort => [ 'documentation', 'path' ],

            _source => [ "module", "abstract" ],

            fields => [
                qw(
                    author
                    authorized
                    distribution
                    documentation
                    indexed
                    path
                    pod_lines
                    release
                    status
                    )
            ],
        }
    );
}

sub find {
    my ( $self, $distribution ) = @_;
    $self->request(
        '/release/_search',
        {
            query => {
                bool => {
                    must => [
                        {
                            term => {
                                'distribution' => $distribution
                            }
                        },
                        { term => { status => 'latest' } }
                    ]
                }
            },
            sort => [ { date => 'desc' } ],
            size => 1
        }
    );
}

# stolen from Module/requires
sub reverse_dependencies {
    my ( $self, $distribution, $page, $page_size, $sort ) = @_;
    $sort ||= { date => 'desc' };

# TODO: do we need to do a taint-check on $distribution before inserting it into the url?
# maybe the fact that it came through as a Catalyst Arg is enough?
    return $self->request(
        "/search/reverse_dependencies/$distribution",
        {
            query => {
                bool => {
                    must => [
                        { term => { 'status'     => 'latest' } },
                        { term => { 'authorized' => 1 } },
                    ]
                }
            },
            size => $page_size,
            from => $page * $page_size - $page_size,
            sort => [$sort],
        }
        )->transform(
        done => sub {
            my $data = shift;
            return {
                data => [ map { $_->{_source} } @{ $data->{hits}->{hits} } ],
                total => $data->{hits}->{total},
                took  => $data->{took}
            };
        }
        );
}

sub interesting_files {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search',
        {
            query => {
                bool => {
                    must => [
                        { term => { release   => $release } },
                        { term => { author    => $author } },
                        { term => { directory => \0 } },
                        { not  => { prefix    => { 'path' => 'xt/' } } },
                        { not  => { prefix    => { 'path' => 't/' } } },
                        {
                            bool => {
                                should => [
                                    {
                                        bool => {
                                            must => [
                                                { term => { level => 0 } },
                                                {
                                                    terms => {
                                                        name => [
                                                            qw(
                                                                AUTHORS
                                                                Build.PL
                                                                CHANGELOG
                                                                CHANGES
                                                                CONTRIBUTING
                                                                CONTRIBUTING.md
                                                                COPYRIGHT
                                                                CREDITS
                                                                ChangeLog
                                                                Changelog
                                                                Changes
                                                                Copying
                                                                FAQ
                                                                INSTALL
                                                                INSTALL.md
                                                                LICENCE
                                                                LICENSE
                                                                MANIFEST
                                                                META.json
                                                                META.yml
                                                                Makefile.PL
                                                                NEWS
                                                                README
                                                                README.markdown
                                                                README.md
                                                                README.mdown
                                                                README.mkdn
                                                                THANKS
                                                                TODO
                                                                ToDo
                                                                Todo
                                                                cpanfile
                                                                dist.ini
                                                                minil.toml
                                                                )
                                                        ]
                                                    }
                                                }
                                            ]
                                        }
                                    },
                                    map {
                                        { prefix     => { 'name' => $_ } },
                                            { prefix => { 'path' => $_ } },

                                 # With "prefix" we don't need the plural "s".
                                        } qw(
                                        ex eg
                                        example Example
                                        sample
                                        )
                                ]
                            }
                        }
                    ]
                }
            },

          # NOTE: We could inject author/release/distribution into each result
          # in the controller if asking ES for less data would be better.
            fields => [
                qw(
                    name documentation path pod_lines
                    author release distribution status
                    )
            ],
            size => 250,
        }
    );
}

sub versions {
    my ( $self, $dist ) = @_;
    $self->request(
        '/release/_search',
        {
            query => { term => { distribution => $dist } },
            size  => 250,
            sort  => [      { date            => 'desc' } ],
            fields =>
                [qw( name date author version status maturity authorized )],
        }
    );
}

sub favorites {
    my $self = shift;
    $self->request( '/favorite/_search', {} );
}

sub topuploaders {
    my ( $self, $range ) = @_;
    my $param = $range ? { range => $range } : ();
    $self->request( '/release/top_uploaders', undef, $param );
}

sub no_latest {
    my ( $self, @distributions ) = @_;

    # If there are no distributions return
    return Future->done( {} ) unless (@distributions);

    @distributions = uniq @distributions;
    $self->request(
        '/release/_search',
        {
            size  => scalar @distributions,
            query => {
                bool => {
                    must => [
                        { terms => { distribution => \@distributions } },
                        { term  => { status       => 'latest' } }
                    ]
                }
            },
            fields => [qw(distribution status)]
        }
        )->transform(
        done => sub {
            my $data = shift;
            my @latest
                = map { $_->{fields}->{distribution} }
                @{ $data->{hits}->{hits} };
            return (
                {
                    took      => $data->{took},
                    no_latest => {
                        map {
                            my $distro = $_;
                            ( first { $_ eq $distro } @latest )
                                ? ()
                                : ( $distro, 1 );
                        } @distributions
                    }
                }
            );
        }
        );
}

__PACKAGE__->meta->make_immutable;

1;
