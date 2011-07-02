package MetaCPAN::Web::Model::Release;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'MetaCPAN::Web::Role::ES';

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
        '/release/_search', {
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

sub recent {
    my ( $self, $page ) = @_;
    $self->request(
        '/release/_search', {
            size  => 100,
            from  => ( $page - 1 ) * 100,
            query => { match_all => {} },
            sort  => [ { 'date' => { order => "desc" } } ]
        }
    );
}

sub modules {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search', {
            query => {
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
                                            }, {term => {
                                                    'file.module.indexed' =>
                                                        \1
                                                }
                                            }
                                        ]
                                    }, {and => [
                                            {   exists => {
                                                    field => 'documentation'
                                                }
                                            }, {term =>
                                                    { 'file.indexed' => \1 }
                                            }
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
                qw(documentation _source.abstract _source.module path status)
            ],
        }
    );
}

sub find {
    my ( $self, $distribution ) = @_;
    $self->request(
        '/release/_search', {
            query => {
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

sub root_files {
    my ( $self, $author, $release ) = @_;
    $self->request(
        '/file/_search', {
            query => {
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
                                        qw(MANIFEST README INSTALL Makefile.PL Build.PL NEWS LICENSE TODO ToDo Todo THANKS FAQ COPYRIGHT CREDITS AUTHORS Copying CHANGES Changes ChangeLog Changelog META.yml META.json dist.ini)
                                ]
                            }
                        ]
                    }
                }
            },
            fields => [qw(name)],
            size   => 100,
        }
    );
}

sub versions {
    my ( $self, $dist ) = @_;
    $self->request(
        '/release/_search', {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { 'release.distribution' => $dist } },
                        ],

                    }
                }
            },
            size   => 100,
            sort   => [ { date => 'desc' } ],
            fields => [qw(name date author version status)],
        }
    );
}
__PACKAGE__->meta->make_immutable;

1;
