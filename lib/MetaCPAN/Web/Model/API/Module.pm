package MetaCPAN::Web::Model::API::Module;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API::File';

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
    = qw(kurila perl_debug perl_mlb perl-5.005_02+apache1.3.3+modperl pod2texi perlbench spodcxx Bundle-Everything);

sub find {
    my ( $self, @path ) = @_;
    $self->request( '/module/' . join( q{/}, @path ) );
}

sub _not_rogue {
    my @rogue_dists = map { { term => { 'file.distribution' => $_ } } }
        @ROGUE_DISTRIBUTIONS;
    return { not => { filter => { or => \@rogue_dists } } };
}

sub autocomplete {
    my ( $self, $query ) = @_;
    my $cv = $self->cv;
    $self->request("/search/autocomplete?q=$query&size=20")->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {
                    results => [
                        map { $_->{fields} } @{ $data->{hits}->{hits} || [] }
                    ]
                }
            );
        }
    );
    return $cv;
}

sub search_expanded {
    my ( $self, $query, $from, $page_size, $user ) = @_;

    # When used for a distribution or module search, the limit is included in
    # the query and ES does the right thing.
    my $cv = $self->cv;
    my ( $data, $total );
    $data = $self->search(
        $query,
        {
            size => $page_size,
            from => $from
        }
    )->recv;
    my @distributions = uniq
        map { $_->{fields}->{distribution} } @{ $data->{hits}->{hits} };

    my @ids          = map { $_->{fields}->{id} } @{ $data->{hits}->{hits} };
    my $descriptions = $self->search_descriptions(@ids);
    my $ratings      = $self->model('Rating')->get(@distributions);
    my $favorites    = $self->model('Favorite')->get( $user, @distributions );
    $_ = $_->recv for ( $ratings, $favorites, $descriptions );
    my $results = $self->_extract_results( $data, $ratings, $favorites );
    map { $_->{description} = $descriptions->{results}->{ $_->{id}[0] } }
        @{$results};
    $cv->send(
        {
            results => [ map { [$_] } @$results ],
            total   => $data->{hits}->{total},
            took => sum( grep {defined} $data->{took}, $ratings->{took} )
        }
    );
    return $cv;
}

sub search_collapsed {
    my ( $self, $query, $from, $page_size, $user ) = @_;
    my $cv   = AE::cv();
    my $took = 0;
    my $total;
    my $run           = 1;
    my $hits          = 0;
    my @distributions = ();
    my $process_or_repeat;
    my $data;
    do {
        $data = $self->_search( $query, $run )->recv;
        $took += $data->{took} || 0;
        $total = @{ $data->{facets}->{count}->{terms} || [] }
            if ( $run == 1 );
        $hits = @{ $data->{hits}->{hits} || [] };
        @distributions = uniq( @distributions,
            map { $_->{fields}->{distribution} } @{ $data->{hits}->{hits} } );
        $run++;
        } while ( @distributions < $page_size + $from
        && $data->{hits}->{total}
        && $data->{hits}->{total} > $hits + ( $run - 2 ) * $RESULTS_PER_RUN );

    @distributions = map { $_->[0] } splice( @distributions, $from, $page_size );
    my $ratings   = $self->model('Rating')->get(@distributions);
    my $favorites = $self->model('Favorite')->get( $user, @distributions );
    my $results   = $self->model('Module')
        ->search( $query, $self->_search_in_distributions(@distributions) );
    $_ = $_->recv for ( $ratings, $favorites, $results );

    $took += max( grep {defined} $ratings->{took},
        $results->{took}, $favorites->{took} )
        || 0;
    $results = $self->_extract_results( $results, $ratings, $favorites );
    $results = $self->_collapse_results($results);
    my @ids = map { $_->[0]{id}[0] } @$results;
    $data = {
        results => $results,
        total   => $total,
        took    => $took,
    };
    my ($descriptions) = $self->search_descriptions(@ids)->recv;
    $data->{took} += $descriptions->{took} || 0;
    map { $_->[0]{description} = $descriptions->{results}{ $_->[0]{id}[0] } }
        @{ $data->{results} };
    $cv->send($data);
    return $cv;
}

sub search_descriptions {
    my ( $self, @ids ) = @_;
    my $cv = $self->cv;
    $self->request(
        '/file/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [ map { { term => { 'file.id' => $_ } } } @ids ]
                    }
                }
            },
            fields  => ['id'],
            _source => 'pod',
            size    => scalar @ids,
        }
    )->cb(
        sub {
            my ($data) = shift->recv;
            my $extract = sub {
                my $pod = shift;
                return undef unless $pod;
                $pod =~ /DESCRIPTION (.*)$/;
                return ( $1 || undef );
            };
            $cv->send(
                {
                    results => {
                        map { $_->{fields}{id}[0] => $extract->( $_->{_source}{pod} ) }
                           @{ $data->{hits}{hits} }
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
            my $res = $_;
            for my $k ( qw/distribution author release path documentation date/ ) {
                $res->{fields}{$k} = $res->{fields}{$k}[0]
                    if ref $res->{fields}{$k} eq 'ARRAY';
            }
            my $dist = $res->{fields}{distribution};
            +{
                %{ $res->{fields} },
                abstract   => $res->{fields}{'abstract.analyzed'}[0],
                score      => $res->{_score},
                rating     => $ratings->{ratings}{$dist},
                favorites  => $favorites->{favorites}{$dist},
                myfavorite => $favorites->{myfavorites}{$dist},
            }
        } @{ $results->{hits}{hits} }
    ];
}

sub _collapse_results {
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
        map  { $collapsed{$_}->{results} }
        sort { $collapsed{$a}->{position} <=> $collapsed{$b}->{position} }
        keys %collapsed
    ];
}

sub _search {
    my ( $self, $query, $run ) = @_;
    return $self->search(
        $query,
        {
            size   => $run * $RESULTS_PER_RUN,
            from   => ( $run - 1 ) * $RESULTS_PER_RUN,
            fields => [qw(distribution)],
            $run == 1
            ? (
                facets => {
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
    $self->search( $query, { fields => [qw(documentation)] } )->cb(
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
    ( my $clean = $query ) =~ s/::/ /g;

    my $negative
        = { term => { 'file.mime' => { value => 'text/x-script.perl' } } };

    my $positive = {
        bool => {
            should => [

                # exact matches result in a huge boost
                {
                    term => {
                        'file.documentation' => {
                            value => $query,
                            boost => 20
                        }
                    }
                },
                {
                    term => {
                        'file.module.name' => {
                            value => $query,
                            boost => 20
                        }
                    }
                },

            # take the maximum score from the module name and the abstract/pod
                {
                    dis_max => {
                        queries => [
                            {
                                query_string => {
                                    fields => [
                                        qw(documentation.analyzed^2 file.module.name.analyzed^2 distribution.analyzed),
                                        qw(documentation.camelcase file.module.name.camelcase distribution.camelcase)
                                    ],
                                    query                  => $clean,
                                    boost                  => 3,
                                    default_operator       => 'AND',
                                    allow_leading_wildcard => \0,
                                    use_dis_max            => \1,

                                }
                            },
                            {
                                query_string => {
                                    fields => [
                                        qw(abstract.analyzed pod.analyzed)
                                    ],
                                    query                  => $clean,
                                    default_operator       => 'AND',
                                    allow_leading_wildcard => \0,
                                    use_dis_max            => \1,

                                }
                            }
                        ]
                    }
                }

            ]
        }
    };

    my $search = merge(
        $params,
        {
            query => {
                filtered => {
                    query => {
                        function_score => {
                            script_score => {
                                script => "len = (doc.documentation.empty ? 26 : doc.documentation.value.length()); _score - len.toDouble()/400;"
                            },
                            query => {
                                boosting => {
                                    negative_boost => 0.5,
                                    negative       => $negative,
                                    positive       => $positive
                                }
                            }
                        }
                    },
                    filter => {
                        and => [
                            $self->_not_rogue,
                            { term => { status            => 'latest' } },
                            { term => { 'file.authorized' => \1 } },
                            { term => { 'file.indexed'    => \1 } },
                            {
                                or => [
                                    {
                                        and => [
                                            {
                                                exists => {
                                                    field =>
                                                        'file.module.name'
                                                }
                                            },
                                            {
                                                term => {
                                                    'file.module.indexed' =>
                                                        \1
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        exists => { field => 'documentation' }
                                    },
                                ]
                            }
                        ]
                    }
                }
            },
            fields => [
                qw(
                    documentation
                    author
                    abstract.analyzed
                    release
                    path
                    status
                    indexed
                    authorized
                    module.name
                    distribution
                    date
                    id
                    pod_lines
                )
            ],
        }
    );
    return $self->request( '/file/_search', $search );
}

sub _search_in_distributions {
    my ( $self, @distributions ) = @_;
    {

# we will probably never hit that limit, since we are searching in $page_size=20 distributions max
        size  => 5000,
        query => {
            filtered => {
                filter => {
                    and => [
                        {
                            or => [
                                map {
                                    { term => { 'file.distribution' => $_ } }
                                } @distributions
                            ]
                        }
                    ]
                }
            }
        }
    };
}

sub requires {
    my ( $self, $module, $page, $page_size, $sort ) = @_;
    $sort ||= { date => 'desc' };
    my $cv = $self->cv;
    $self->request(
        '/release/_search',
        {
            query => {
                filtered => {
                    query  => { 'match_all' => {} },
                    filter => {
                        and => [
                            { term => { 'release.status'     => 'latest' } },
                            { term => { 'release.authorized' => \1 } },
                            {
                                term => {
                                    'release.dependency.module' => $module
                                }
                            }
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

__PACKAGE__->meta->make_immutable;
