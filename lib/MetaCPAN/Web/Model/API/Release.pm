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
    $self->request(
        '/release/recent',
        undef,
        {
            page      => $page,
            page_size => $page_size,
            type      => $type,
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

    return $self->request( "/reverse_dependencies/dist/$distribution",
        undef, { sort => $sort } );
}

sub interesting_files {
    my ( $self, $author, $release ) = @_;
    $self->request("/release/interesting_files/$author/$release");
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

sub topuploaders {
    my ( $self, $range ) = @_;
    my $param = $range ? { range => $range } : ();
    $self->request( '/release/top_uploaders', undef, $param );
}

__PACKAGE__->meta->make_immutable;

1;
