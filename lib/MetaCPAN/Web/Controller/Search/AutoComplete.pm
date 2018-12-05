package MetaCPAN::Web::Controller::Search::AutoComplete;

use Moose;
use Cpanel::JSON::XS ();
use List::Util qw(uniq);

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $query       = join( q{ }, $c->req->param('q') );
    my $module_data = $c->model('API::Module')->autocomplete($query);
    my $author_data = $c->model('API::Author')->search($query);
    my @results     = (
        (
            map +{
                value => join( ' - ',
                    $_->{pauseid}, $_->{name} || $_->{asciiname} || () ),
                data => { id => $_->{pauseid}, type => 'author' }
            },
            @{ $author_data->get->{authors} }
        ),
        (
            map +{ value => $_, data => { module => $_, type => 'module' } },
            uniq map { $_->{name} } @{ $module_data->get->{results} }
        ),
    );

    $c->res->content_type('application/json');
    $c->res->body( Cpanel::JSON::XS::encode_json(
        { suggestions => \@results } ) );
}

__PACKAGE__->meta->make_immutable;

1;
