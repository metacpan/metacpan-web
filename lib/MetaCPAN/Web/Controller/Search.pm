package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use List::Util qw( sum );
use Plack::Response;

sub index {
    my ($self, $req) = @_;
    my $cv = AE::cv;
    my @query = ($req->parameters->get_all('q'), $req->parameters->get_all('lucky'));
    my $query = join(' ', @query);
    $query =~ s/::/ /g if($query);
    my ($data, $results);
    $self->model->request(
      '/file/_search',
      { size => $req->parameters->{lucky} ? 1 : 20,
        from => ( $req->page - 1 ) * 20,
        query => { filtered => { query => {
          custom_score => {
            query => {
              query_string => {
                fields => [
                  'documentation.analyzed^99', 'documentation.camelcase^99',
                  'abstract.analyzed^5',       'pod.analyzed'
                ],
                query                  => $query,
                allow_leading_wildcard => \0,
                default_operator       => 'AND'
              }
            },
            # prefer shorter module names slightly
            script => "_score - doc['documentation'].stringValue.length()/10000 + doc[\"date\"].date.getMillis() / 1000000000000"
          }
        },
        filter => {
          and => [
            { term => { status => 'latest' } },
            {
              or => [
                {
                  and => [
                    { exists => { field => 'file.module.name' } },
                    { term => { 'file.module.indexed' => \1 } } ]
                },
                {
                  and => [
                    { exists => { field          => 'documentation' } },
                    { term   => { 'file.indexed' => \1 } } ] } ] } ]
        } } },
        fields    => [qw(documentation author abstract.analyzed release path status distribution date)],
        highlight => {
          fields    => { 'pod.analyzed' => { "fragment_size" => 250, "number_of_fragments" => 2, } },
          order     => 'score',
          pre_tags  => ["[% b %]"],
          post_tags => ["[% /b %]"],
      } } )->(sub {
        $data = shift->recv;
        $results = [
            map {
                {
                    %{ $_->{fields} },
                      abstract => $_->{fields}->{'abstract.analyzed'},
                      score    => $_->{_score},
                      preview  => $_->{highlight}->{'pod.analyzed'}
                }
              } @{ $data->{hits}->{hits} } ];
        if($req->parameters->{lucky} && $data->{hits}->{total}) {
            my $res = Plack::Response->new;
            $res->redirect('/module/' . $results->[0]->{documentation});
            $cv->send($res);
            return $cv;
        } else {
            return $self->model('Rating')->get(map { $_->{distribution} } @$results);
        }
    })->(sub {
        my ($ratings) = shift->recv;
        $results = [
            map {
                { %$_, rating => $ratings->{ratings}->{ $_->{distribution} } }
              } @$results ];
        $cv->send(
            {   results => $results,
                total   => $data->{hits}->{total},
                took    => sum( grep { defined } $data->{took}, $ratings->{took} ) } );
    });
    return $cv;
}

1;
