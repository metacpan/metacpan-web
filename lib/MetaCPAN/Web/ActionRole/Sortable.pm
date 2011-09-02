package MetaCPAN::Web::ActionRole::Sortable;

use Moose::Role;

# Config necessary! See example in Controller::Requires

around execute => sub {
    my $orig = shift;
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $order   = [qw(asc desc)];
    my $action  = $c->action;
    my $config  = $controller->config->{sort}{ $c->action->name };
    my $columns = $config->{columns} or die 'Config required!';
    my $sort    = { column => $columns->[0], order => $order->[0] };

    if ( $config->{default} ) {
        $sort = {
            column => $config->{default}[0],
            order  => $config->{default}[1],
        };
    }

    if ( my $param = $c->req->param('sort') ) {
        my ( $p_column, $p_order ) = $param =~ /(\d+),(\d+)/;

        $sort->{column} = $config->{columns}[$p_column]
            if defined $p_column && defined $config->{columns}[$p_column];

        $sort->{order} = $order->[$p_order]
            if defined $p_order && defined $order->[$p_order];
    }

    return $self->$orig( @_, { $sort->{column} => $sort->{order} } );
};

1;
