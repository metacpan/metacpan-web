package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index {
    my ($self, $req) = @_;
    my $cv = AE::cv;
    my $query = $req->parameters->{q} || $req->parameters->{lucky};
    $query =~ s/::/ /g;
    $self->model('/file/_search', {
        size => $req->parameters->{lucky} ? 1 : 50,
        query => {
            query_string=> {
                fields=> ['documentation.analyzed^99', 'documentation.camelcase^99', 'abstract.analyzed^5', 'pod.analyzed'],
                query=> $query,
                allow_leading_wildcard=> \0,
                default_operator => 'AND'
            }
        },
        filter => {
            and => [ { term => { status => 'latest' } },
                     {
                        or => [
                               {
                                   and => [
                                            { exists =>
                                                { field => 'file.module.name' }
                                            },
                                            { term =>
                                                { 'file.module.indexed' => \1 }
                                            } ]
                               },
                               {
                                   and => [
                                       {  exists => { field => 'documentation' }
                                       },
                                       { term => { 'file.indexed' => \1 } } ] }
                        ] } ]
          },

        highlight => {
                fields => {
                    'pod.analyzed' => {
                        "number_of_fragments"=> 5,
                    }
                },
                order=> 'score',
                pre_tags => ["[% b %]"],
                post_tags => ["[% /b %]"],
        },
    })->(sub {
        my $data = shift->recv;
        my $latest = [map { { %{$_->{_source}}, preview => $_->{highlight}->{'pod.analyzed'}} } @{$data->{hits}->{hits}}];
        if($req->parameters->{lucky} && $data->{hits}->{total}) {
            my $res = Plack::Response->new;
            $res->redirect('/module/' . $latest->[0]->{documentation});
            $cv->send($res);
        } else {
            $cv->send({ results => $latest, total => $data->{hits}->{total}, took => $data->{took} });
        }
    });
    return $cv;
}

1;