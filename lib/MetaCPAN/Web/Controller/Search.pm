package MetaCPAN::Web::Controller::Search;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Plack::Response;

sub index {
    my ( $self, $req ) = @_;
    my @query =
      ( $req->parameters->get_all('q'), $req->parameters->get_all('lucky') );
    my $query = join( ' ', @query );
    $query =~ s/::/ /g if ($query);

    my $model = $self->model('Module');
    my $from  = ( $req->page - 1 ) * 20;
    return $req->parameters->{lucky}
      ? $model->first($query)->(
        sub {
            my $module = shift->recv;
            return $self->not_found unless ($module);
            my $res = Plack::Response->new;
            $res->redirect( '/module/' . $module );
            return $res;
        }
      )
      : $query =~ /distribution:/ ? $model->search_distribution( $query, $from )
      :                             $model->search_collapsed( $query, $from );
}

1;
