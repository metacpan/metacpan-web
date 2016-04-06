package MetaCPAN::Web::Model::API::Release;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

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
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { 'name' => $release } },
                            { term => { author => uc($author) } }
                        ]
                    }
                }
            }
        }
    );
}

sub distribution {
    my ( $self, $dist ) = @_;
    $self->request("/distribution/$dist");
}

sub _new_distributions_query {
    return {
        constant_score => {
            filter => {
                and => [
                    { term => { first => \1, } },
                    {
                        not =>
                            { filter => { term => { status => 'backpan' } } }
                    },
                ]
            }
        }
    };
}

sub latest_by_author {
    my ( $self, $author ) = @_;
    return $self->request(
        '/release/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { author => uc($author) } },
                            { term => { status => 'latest' } }
                        ]
                    },
                }
            },
            sort => [
                'distribution', { 'version_numified' => { reverse => \1 } }
            ],
            fields => [qw(author distribution name status abstract date)],
            size   => 1000,
        }
    );
}

sub all_by_author {
    my ( $self, $author, $size, $page ) = @_;

    $page = $page > 0 ? $page : 1;

    return $self->request(
        '/release/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        term => { author => uc($author) }
                    },
                }
            },
            sort => [ { date => 'desc' } ],
            fields => [qw(author distribution name status abstract date)],
            size   => $size,
            from   => ( $page - 1 ) * $size,
        }
    );
}

sub recent {
    my ( $self, $page, $page_size, $type ) = @_;
    my $query;
    if ( $type eq 'n' ) {
        $query = $self->_new_distributions_query;
    }
    elsif ( $type eq 'a' ) {
        $query = { match_all => {} };
    }
    else {
        $query = {
            constant_score => {
                filter => {
                    not => { filter => { term => { status => 'backpan' } } }
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
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { release => $release } },
                            { term => { author  => $author } },
                            {
                                or => [
                                    {
                                        and => [
                                            {
                                                exists => {
                                                    field =>
                                                        'module.name'
                                                }
                                            },
                                            {
                                                term => {
                                                    'module.indexed' =>
                                                        \1
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        and => [
                                            {
                                                exists => {
                                                    field =>
                                                        'pod.analyzed'
                                                }
                                            },
                                            {
                                                term =>
                                                    { 'indexed' => \1 }
                                            },
                                        ]
                                    }
                                ]
                            }
                        ]
                    }
                }
            },
            size => 999,

            # Sort by documentation name; if there isn't one, sort by path.
            sort => [ 'documentation', 'path' ],

            # Get indexed and authorized from _source to work around ES bug:
            # https://github.com/CPAN-API/metacpan-web/issues/881
            # https://github.com/elasticsearch/elasticsearch/issues/2551
            fields => [
                qw(
                    documentation path status author release
                    pod_lines
                    distribution
                    _source.abstract  _source.module
                    _source.indexed   _source.authorized
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
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            {
                                term => {
                                    'distribution' => $distribution
                                }
                            },
                            { term => { status => 'latest' } }
                        ]
                    }
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
    my $cv = $self->cv;

# TODO: do we need to do a taint-check on $distribution before inserting it into the url?
# maybe the fact that it came through as a Catalyst Arg is enough?
    $self->request(
        "/search/reverse_dependencies/$distribution",
        {
            query => {
                filtered => {
                    query  => { 'match_all' => {} },
                    filter => {
                        and => [
                            { term => { 'status'     => 'latest' } },
                            { term => { 'authorized' => \1 } },
                        ]
                    }
                }
            },
            size => $page_size,
            from => $page * $page_size - $page_size,
            sort => [$sort],
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {
                    data =>
                        [ map { $_->{_source} } @{ $data->{hits}->{hits} } ],
                    total => $data->{hits}->{total},
                    took  => $data->{took}
                }
            );
        }
        );
    return $cv;
}

sub interesting_files {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { release   => $release } },
                            { term => { author    => $author } },
                            { term => { directory => \0 } },
                            {
                                or => [
                                    {
                                        and => [
                                            { term => { level => 0 } },
                                            {
                                                or => [
                                                    map {
                                                        {
                                                            term => {
                                                                'name'
                                                                    => $_
                                                            }
                                                        }
                                                        } qw(
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
                                                        )
                                                ]
                                            }
                                        ]
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
                        ]
                    }
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
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { 'distribution' => $dist } },
                        ],

                    }
                }
            },
            size   => 250,
            sort   => [ { date => 'desc' } ],
            fields => [
                qw(
                    name date author version status maturity
                    _source.authorized
                    )
            ],
        }
    );
}

sub favorites {
    my ( $self, $dist ) = @_;
    $self->request( '/favorite/_search', {} );
}

sub topuploaders {
    my ( $self, $range ) = @_;
    my $range_filter = {
        range => {
            date => {
                from => $range eq 'all' ? 0 : DateTime->now->subtract(
                      $range eq 'weekly'  ? 'weeks'
                    : $range eq 'monthly' ? 'months'
                    : $range eq 'yearly'  ? 'years'
                    :                       'weeks' => 1
                )->truncate( to => 'day' )->iso8601
            },
        }
    };
    $self->request(
        '/release/_search',
        {
            query  => { match_all => {} },
            aggregations => {
                author => {
                    terms        => { field => 'author', size => 50 },
                    facet_filter => $range_filter,
                },
            },
            size => 0,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
