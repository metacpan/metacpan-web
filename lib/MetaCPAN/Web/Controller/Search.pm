package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ($self, $req) = @_;
    my $cv = AE::cv;
    my $query = $req->parameters->{q};
    $query =~ s/::/ /g;
    $self->model('/file/_search', {
        size => 50,
        query => {
            query_string=> {
                fields=> ['pod', 'abstract^2', 'documentation^99'],
                query=> $query,
                allow_leading_wildcard=> \0,
                default_operator => 'AND'
            }
        },
        filter => {
            and => [{
                term => {
                    status => 'latest'
                }
            }]
        },
        highlight => {
                fields => {
                    pod => {
                        "number_of_fragments"=> 5,
                    }
                },
                order=> 'score',
                pre_tags => ["[% b %]"],
                post_tags => ["[% /b %]"],
        },
    })->(sub {
        my $data = shift->recv;
        my $latest = [map { { %{$_->{_source}}, preview => $_->{highlight}->{pod}} } @{$data->{hits}->{hits}}];
        $cv->send({ results => $latest, total => $data->{hits}->{total}, took => $data->{took} });
    });
    return $cv;
}

1;