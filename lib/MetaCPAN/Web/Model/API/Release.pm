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
        {   query => {
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
    $self->request( "/distribution/$dist" );
}


sub _new_distributions_query {
    return {
        constant_score => {
            filter => {
                and => [
                    { term => { first => \1, } },
                    {   not =>
                            { filter => { term => { status => 'backpan' } } }
                    },
                ]
            }
        }
    };
}

sub latest_by_author {
    my ($self, $author) = @_;
    return $self->request(
        '/release/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { author => uc( $author ) } },
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

sub recent {
    my ( $self, $page, $type ) = @_;
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
        {   size  => 100,
            from  => ( $page - 1 ) * 100,
            query => $query,
            sort  => [ { 'date' => { order => "desc" } } ]
        }
    );
}

sub modules {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { release => $release } },
                            { term => { author  => $author } },
                            {   or => [
                                    {   and => [
                                            {   exists => {
                                                    field =>
                                                        'file.module.name'
                                                }
                                            },
                                            {   term => {
                                                    'file.module.indexed' =>
                                                        \1
                                                }
                                            }
                                        ]
                                    },
                                    {   and => [
                                            {   exists => {
                                                    field =>
                                                        'file.pod.analyzed'
                                                }
                                            },
                                            {   term =>
                                                    { 'file.indexed' => \1 }
                                            },
                                        ]
                                    }
                                ]
                            }
                        ]
                    }
                }
            },
            size   => 999,
            sort   => ['documentation'],
            fields => [
                qw(documentation _source.abstract _source.module path status author release)
            ],
        }
    );
}

sub find {
    my ( $self, $distribution ) = @_;
    $self->request(
        '/release/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            {   term => {
                                    'release.distribution' => $distribution
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
    my ( $self, $distribution, $page, $sort ) = @_;
    $sort ||= { date => 'desc' };
    my $cv = $self->cv;
    # TODO: do we need to do a taint-check on $distribution before inserting it into the url?
    # maybe the fact that it came through as a Catalyst Arg is enough?
    $self->request(
        "/search/reverse_dependencies/$distribution",
        {   query => {
                filtered => {
                    query  => { "match_all" => {} },
                    filter => {
                        and => [
                            { term => { 'release.status'     => 'latest' } },
                            { term => { 'release.authorized' => \1 } },
                        ]
                    }
                }
            },
            size => 50,
            from => $page * 50 - 50,
            sort => [$sort],
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {   data =>
                        [ map { $_->{_source} } @{ $data->{hits}->{hits} } ],
                    total => $data->{hits}->{total},
                    took  => $data->{took}
                }
            );
        }
        );
    return $cv;
}

sub root_files {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { release   => $release } },
                            { term => { author    => $author } },
                            { term => { level     => 0 } },
                            { term => { directory => \0 } },
                            {   or => [
                                    map { { term => { 'file.name' => $_ } } }
                                        qw(
                                            MANIFEST
                                            README README.md README.pod
                                            INSTALL
                                            Makefile.PL Build.PL
                                            NEWS LICENSE TODO ToDo Todo
                                            THANKS FAQ
                                            COPYRIGHT CREDITS AUTHORS
                                            Copying
                                            CHANGES Changes ChangeLog Changelog CHANGELOG
                                            META.yml META.json
                                            cpanfile
                                            dist.ini
                                        )
                                ]
                            }
                        ]
                    }
                }
            },
            fields => [qw(name documentation)],
            size   => 100,
        }
    );
}

sub versions {
    my ( $self, $dist ) = @_;
    $self->request(
        '/release/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { 'release.distribution' => $dist } },
                        ],

                    }
                }
            },
            size   => 250,
            sort   => [ { date => 'desc' } ],
            fields => [qw(name date author version status maturity)],
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
                    : 'weeks' => 1
                    )->truncate( to => 'day' )->iso8601
            },
        }
    };
    $self->request(
        '/release/_search',
        {   query  => { match_all => {} },
            facets => {
                author => {
                    terms        => { field => "author", size => 50 },
                    facet_filter => $range_filter,
                },
            },
            size => 0,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
