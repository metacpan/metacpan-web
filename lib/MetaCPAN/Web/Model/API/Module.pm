package MetaCPAN::Web::Model::API::Module;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

=head1 NAME

MetaCPAN::Web::Model::Module - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Moritz Onken, Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Hash::Merge qw( merge );

use List::Util qw( max sum );
use List::MoreUtils qw(uniq);

my $RESULTS_PER_RUN = 200;
my @ROGUE_DISTRIBUTIONS
    = qw(kurila perl_debug perl-5.005_02+apache1.3.3+modperl pod2texi perlbench spodcxx);

sub find {
    my ( $self, $module ) = @_;
    $self->request("/module/$module");
}

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/file/' . join( '/', @path ) );
}

sub source {
    my ( $self, @module ) = @_;
    $self->request( '/source/' . join( '/', @module ), undef, { raw => 1 } );
}

sub autocomplete {
    my ( $self, $query ) = @_;
    my $cv     = $self->cv;
    my @query  = split( /\s+/, $query );
    my $should = [
        map {
            { field     => { 'documentation.analyzed'  => "$_*" } },
                { field => { 'documentation.camelcase' => "$_*" } }
            } grep {$_} @query
    ];
    $self->request(
        '/file/_search',
        {   query => {
                filtered => {
                    query => {
                        custom_score => {
                            query => { bool => { should => $should } },
                            script =>
                                "_score - doc['documentation'].stringValue.length()/100"
                        },
                    },
                    filter => {
                        and => [
                            {   not => {
                                    filter => {
                                        or => [
                                            map {
                                                {   term => {
                                                        'file.distribution' =>
                                                            $_
                                                    }
                                                }
                                                } @ROGUE_DISTRIBUTIONS
                                        ]
                                    }
                                }
                            },
                            { exists => { field => 'documentation' } },
                            { term => { 'file.indexed' => \1 } },
                            { term => { 'file.status'  => 'latest' } },
                            {   not => {
                                    filter => {
                                        term => { 'file.authorized' => \0 }
                                    }
                                }
                            }
                        ]
                    }
                }
            },
            fields => [qw(documentation release author distribution)],
            size   => 20,
        }
        )->(
        sub {
            my $data = shift->recv;
            $cv->send(
                {   results => [
                        map { $_->{fields} } @{ $data->{hits}->{hits} || [] }
                    ]
                }
            );
        }
        );
    return $cv;
}

sub search_distribution {
    my ( $self, $query, $from, $user ) = @_;

    # the distribution is included in the query and ES does the right thing
    my $cv = $self->cv;
    my ( $data, $total );
    my $results = $self->search(
        $query,
        {   size => 20,
            from => $from
        }
        )->(
        sub {
            $data = shift->recv;
            my @distributions = uniq
                map { $_->{fields}->{distribution} }
                @{ $data->{hits}->{hits} };

            my @ids = map { $_->{fields}->{id} } @{ $data->{hits}->{hits} };
            my $descriptions = $self->search_descriptions(@ids);
            my $ratings      = $self->model('Rating')->get(@distributions);
            my $favorites
                = $self->model('Favorite')->get( $user, @distributions );
            return $ratings & $favorites & $descriptions;
        }
        )->(
        sub {
            my ( $ratings, $favorites, $descriptions ) = shift->recv;
            my $results
                = $self->_extract_results( $data, $ratings, $favorites );

            map { $_->{description} = $descriptions->{results}->{ $_->{id} } }
                @{$results};
            $cv->send(
                {   results => [ map { [$_] } @$results ],
                    total   => $data->{hits}->{total},
                    took =>
                        sum( grep {defined} $data->{took}, $ratings->{took} )
                }
            );
        }
        );

    return $cv;
}

sub search_collapsed {
    my ( $self, $query, $from, $user ) = @_;
    my $cv   = AE::cv();
    my $took = 0;
    my $total;
    my $run           = 1;
    my @distributions = ();
    my $process_or_repeat;
    $process_or_repeat = sub {
        my $data = shift->recv;
        $took += $data->{took} || 0;
        $total = @{ $data->{facets}->{count}->{terms} || [] }
            if ( $run == 1 );
        my $hits = @{ $data->{hits}->{hits} || [] };
        @distributions = uniq( @distributions,
            map { $_->{fields}->{distribution} } @{ $data->{hits}->{hits} } );
        if (   @distributions < 20 + $from
            && $data->{hits}->{total}
            && $data->{hits}->{total}
            > $hits + ( $run - 1 ) * $RESULTS_PER_RUN )
        {

            # need to get more results to satisfy at least 20 results
            $run++;
            my $cv = $self->cv;    # intermediate CV that allows for recursion
            $self->_search( $query, $run )->($process_or_repeat)
                ->( sub { $cv->send( shift->recv ) } );
            return $cv;
        }

        @distributions = splice( @distributions, $from, 20 );
        my $ratings = $self->model('Rating')->get(@distributions);
        my $favorites
            = $self->model('Favorite')->get( $user, @distributions );
        my $results
            = $self->model('Module')
            ->search( $query,
            $self->_search_in_distributions(@distributions) );
        return ( $ratings & $favorites & $results );
    };

    my $data;
    $self->_search( $query, $run )->($process_or_repeat)->(
        sub {
            my ( $ratings, $favorites, $results ) = shift->recv;
            $took += max( grep {defined} $ratings->{took},
                $results->{took}, $favorites->{took} )
                || 0;
            $results
                = $self->_extract_results( $results, $ratings, $favorites );
            $results = $self->_collpase_results($results);
            my @ids = map { $_->[0]->{id} } @$results;
            $data = {
                results => $results,
                total   => $total,
                took    => $took,
            };
            return $self->search_descriptions(@ids);
        }
        )->(
        sub {
            my ($descriptions) = shift->recv;
            $data->{took} += $descriptions->{took} || 0;
            map {
                $_->[0]->{description}
                    = $descriptions->{results}->{ $_->[0]->{id} }
            } @{ $data->{results} };
            $cv->send($data);
        }
        );
    return $cv;
}

sub search_descriptions {
    my ( $self, @ids ) = @_;
    my $cv = $self->cv;
    $self->request(
        '/file/_search',
        {   query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [ map { { term => { 'file.id' => $_ } } } @ids ]
                    }
                }
            },
            fields => [qw(_source.pod id)],
            size   => scalar @ids,
        }
        )->(
        sub {
            my ($data) = shift->recv;
            my $extract = sub {
                my $pod = shift;
                $pod =~ /DESCRIPTION (.*)$/;
                return $1 || undef;
            };
            $cv->send(
                {   results => {
                        map {
                            $_->{fields}->{id} =>
                                $extract->( $_->{fields}->{'_source.pod'} )
                            } @{ $data->{hits}->{hits} }
                    },
                    took => $data->{took}
                }
            );
        }
        );
    return $cv;
}

sub _extract_results {
    my ( $self, $results, $ratings, $favorites ) = @_;
    return [
        map {
            {
                %{ $_->{fields} },
                    abstract => $_->{fields}->{'abstract.analyzed'},
                    score    => $_->{_score},
                    rating =>
                    $ratings->{ratings}->{ $_->{fields}->{distribution} },
                    favorites =>
                    $favorites->{favorites}->{ $_->{fields}->{distribution} },
                    myfavorite => $favorites->{myfavorites}
                    ->{ $_->{fields}->{distribution} },
            }
            } @{ $results->{hits}->{hits} }
    ];
}

sub _collpase_results {
    my ( $self, $results ) = @_;
    my %collapsed;
    foreach my $result (@$results) {
        my $distribution = $result->{distribution};
        $collapsed{$distribution}
            = { position => scalar keys %collapsed, results => [] }
            unless ( $collapsed{$distribution} );
        push( @{ $collapsed{$distribution}->{results} }, $result );
    }
    return [
        map      { $collapsed{$_}->{results} }
            sort { $collapsed{$a}->{position} <=> $collapsed{$b}->{position} }
            keys %collapsed
    ];
}

sub _search {
    my ( $self, $query, $run ) = @_;
    return $self->search(
        $query,
        {   size   => $run * $RESULTS_PER_RUN,
            from   => ( $run - 1 ) * $RESULTS_PER_RUN,
            fields => [qw(distribution)],
            $run == 1
            ? ( facets => {
                    count =>
                        { terms => { size => 999, field => 'distribution' } }
                }
                )
            : (),
        }
    );
}

sub first {
    my ( $self, $query ) = @_;
    my $cv = $self->cv;
    $self->search( $query, { fields => [qw(documentation)] } )->(
        sub {
            my ($result) = shift->recv;
            return $cv->send(undef) unless ( $result->{hits}->{total} );
            $cv->send(
                $result->{hits}->{hits}->[0]->{fields}->{documentation} );
        }
    );
    return $cv;
}

sub search {
    my ( $self, $query, $params ) = @_;
    my $search = merge(
        $params,
        {   query => {
                filtered => {
                    query => {
                        custom_score => {
                            query => {
                                query_string => {
                                    fields => [
                                        'documentation.analyzed^7',
                                        'documentation.camelcase^3',
                                        'file.module.name.analyzed^3',
                                        'file.module.name.camelcase^3',
                                        'distribution.analyzed^10',
                                        'distribution.camelcase^5',
                                        'abstract.analyzed^2',
                                        'pod.analyzed',
                                    ],
                                    query                  => $query,
                                    allow_leading_wildcard => \0,
                                    default_operator       => 'AND'
                                }
                            },

                            # prefer shorter module names slightly
                            script => qq{
    documentation = doc['documentation'].stringValue;
    if(documentation == empty) {
        documentation = 'xxxxxxxxxxxxxxxxxxxxxxxxx'
    }
    return _score - documentation.length()/30 + doc[\"date\"].date.getMillis() / 1000000000000
}
                        }
                    },
                    filter => {
                        and => [
                            {   not => {
                                    filter => {
                                        or => [
                                            map {
                                                {   term => {
                                                        'file.distribution' =>
                                                            $_
                                                    }
                                                }
                                                } @ROGUE_DISTRIBUTIONS
                                        ]
                                    }
                                }
                            },
                            { term => { status => 'latest' } },
                            {   or => [

                            # we are looking for files that have no authorized
                            # property (e.g. .pod files) and files that are
                            # authorized
                                    {   missing =>
                                            { field => 'file.authorized' }
                                    },
                                    { term => { 'file.authorized' => \1 } },
                                ]
                            },
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
                                                    field => 'documentation'
                                                }
                                            },
                                            {   term =>
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
            fields => [
                qw(documentation author abstract.analyzed release path status distribution date id)
            ],
        }
    );
    return $self->request( '/file/_search', $search );
}

sub _search_in_distributions {
    my ( $self, @distributions ) = @_;
    {

# we will probably never hit that limit, since we are searching in 20 distributions max
        size  => 9999,
        query => {
            filtered => {
                filter => {
                    and => [
                        {   or => [
                                map {
                                    { term => { 'file.distribution' => $_ } }
                                    } @distributions
                            ]
                        }
                    ]
                }
            }
        } };
}

sub requires {
    my ( $self, $module, $page ) = @_;
    my $cv = $self->cv;
    $self->request(
        '/release/_search',
        {   query => {
                filtered => {
                    query  => { "match_all" => {} },
                    filter => {
                        and => [
                            { term => { 'release.status'     => 'latest' } },
                            { term => { 'release.authorized' => \1 } },
                            {   term => {
                                    "release.dependency.module" => $module
                                }
                            }
                        ]
                    }
                }
            },
            size => 50,
            from => $page * 50 - 50,
            sort => [{date => 'desc'}],
        }
        )->(
        sub {
            my $data = shift->recv;
            $cv->send(
                {   data  => [map { $_->{_source} } @{$data->{hits}->{hits}}],
                    total => $data->{hits}->{total},
                    took  => $data->{took}
                }
            );
        }
        );
    return $cv;
}

__PACKAGE__->meta->make_immutable;
