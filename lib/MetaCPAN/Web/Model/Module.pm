package MetaCPAN::Web::Model::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Model';
use Hash::Merge qw( merge );

use List::Util qw( sum );
use List::MoreUtils qw(uniq);

my $RESULTS_PER_RUN = 200;

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
            { field   => { 'documentation.analyzed'  => "$_*" } },
              { field => { 'documentation.camelcase' => "$_*" } }
          } grep { $_ } @query
    ];
    $self->request(
        '/file/_search',
        {
            query => {
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
                            { exists => { field          => 'documentation' } },
                            { term   => { 'file.indexed' => \1 } },
                            { term   => { 'file.status'  => 'latest' } },
                            {
                                not => {
                                    filter =>
                                      { term => { 'file.authorized' => \0 } }
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
                {
                    results =>
                      [ map { $_->{fields} } @{ $data->{hits}->{hits} || [] } ]
                }
            );
        }
      );
    return $cv;
}

sub search_distribution {
    my ( $self, $query, $from ) = @_;

    # the distribution is included in the query and ES does the right thing
    my $cv = $self->cv;
    my ( $data, $total );
    my $results = $self->search(
        $query,
        {
            size      => 20,
            from      => $from,
            highlight => {
                fields => {
                    'pod.analyzed' => {
                        "fragment_size"       => 250,
                        "number_of_fragments" => 1,
                    }
                },
                order     => 'score',
                pre_tags  => ["[% b %]"],
                post_tags => ["[% /b %]"],
            },
        }
      )->(
        sub {
            $data = shift->recv;
            my @distributions = uniq
              map { $_->{fields}->{distribution} } @{ $data->{hits}->{hits} };
            return $self->model('Rating')->get(@distributions);
        }
      )->(
        sub {
            my $ratings = shift->recv;
            my $results = $self->_extract_results( $data, $ratings );
            $cv->send(
                {
                    results => [ map { [$_] } @$results ],
                    total   => $data->{hits}->{total},
                    took =>
                      sum( grep { defined } $data->{took}, $ratings->{took} )
                }
            );
        }
      );

    return $cv;
}

sub search_collapsed {
    my ( $self, $query, $from ) = @_;
    my $cv   = AE::cv;
    my $took = 0;
    my $total;
    my $run           = 1;
    my @distributions = ();
    my $process_or_repeat;
    $process_or_repeat = sub {
        my $data = shift->recv;
        $took += $data->{took};
        $total = @{ $data->{facets}->{count}->{terms} } if ( $run == 1 );
        my $hits = @{ $data->{hits}->{hits} };
        @distributions =
          uniq( @distributions,
            map { $_->{fields}->{distribution} } @{ $data->{hits}->{hits} } );
        if (   @distributions < 20 + $from
            && $total > $hits + ( $run - 1 ) * $RESULTS_PER_RUN )
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
        my $results =
          $self->model('Module')
          ->search( $query, $self->_search_in_distributions(@distributions) );
        return ( $ratings & $results );
    };

    $self->_search( $query, $run )->($process_or_repeat)->(
        sub {
            my ( $ratings, $results ) = shift->recv;
            $took += $results->{took};
            $results = $self->_extract_results( $results, $ratings );
            $results = $self->_collpase_results($results);

            $cv->send(
                {
                    results => $results,
                    total   => $total,
                    took    => sum( grep { defined } $took, $ratings->{took} )
                }
            );
        }
    );
    return $cv;
}

sub _extract_results {
    my ( $self, $results, $ratings ) = @_;
    return [
        map {
            {
                %{ $_->{fields} },
                  abstract => $_->{fields}->{'abstract.analyzed'},
                  score    => $_->{_score},
                  preview  => $_->{highlight}->{'pod.analyzed'},
                  rating =>
                  $ratings->{ratings}->{ $_->{fields}->{distribution} }
            }
          } @{ $results->{hits}->{hits} }
    ];
}

sub _collpase_results {
    my ( $self, $results ) = @_;
    my %collapsed;
    foreach my $result (@$results) {
        my $distribution = $result->{distribution};
        $collapsed{$distribution} =
          { position => scalar keys %collapsed, results => [] }
          unless ( $collapsed{$distribution} );
        push( @{ $collapsed{$distribution}->{results} }, $result );
    }
    return [
        map    { $collapsed{$_}->{results} }
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
        {
            query => {
                filtered => {
                    query => {
                        custom_score => {
                            query => {
                                query_string => {
                                    fields => [
                                        'documentation.analyzed^99',
                                        'documentation.camelcase^99',
                                        'abstract.analyzed^5',
                                        'pod.analyzed'
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
        documentation = ''
    }
    return _score - documentation.length()/10000 + doc[\"date\"].date.getMillis() / 1000000000000
}
                        }
                    },
                    filter => {
                        and => [
                            { term => { status => 'latest' } },
                            {
                                or => [
                                # we are looking for files that have no authorized
                                # property (e.g. .pod files) and files that are
                                # authorized
                                    { missing => { field => 'file.authorized' } },
                                    { term => { 'file.authorized' => \1 } },
                                ]
                            },
                            {
                                or => [
                                    {
                                        and => [
                                            {
                                                exists => {
                                                    field => 'file.module.name'
                                                }
                                            },
                                            {
                                                term => {
                                                    'file.module.indexed' => \1
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        and => [
                                            {
                                                exists =>
                                                  { field => 'documentation' }
                                            },
                                            {
                                                term => { 'file.indexed' => \1 }
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
                qw(documentation author abstract.analyzed release path status distribution date)
            ],
        }
    );
    return $self->request( '/file/_search', $search );
}

sub _search_in_distributions {
    my ( $self, @distributions ) = @_;
    {

# we will probably never hit that limit, since we are searching in 20 distributions max
        size      => 9999,
        highlight => {
            fields => {
                'pod.analyzed' => {
                    "fragment_size"       => 250,
                    "number_of_fragments" => 1,
                }
            },
            order     => 'score',
            pre_tags  => ["[% b %]"],
            post_tags => ["[% /b %]"],
        },
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
        } };
}

1;
