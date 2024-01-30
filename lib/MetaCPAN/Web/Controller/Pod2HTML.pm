package MetaCPAN::Web::Controller::Pod2HTML;

use Moose;

use Encode qw( decode DIE_ON_ERR LEAVE_SRC );

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub pod2html : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $pod;
    if ( my $pod_file = $c->req->upload('pod_file') ) {
        my $raw_pod = $pod_file->slurp;
        eval {
            $pod = decode( 'UTF-8', $raw_pod, DIE_ON_ERR | LEAVE_SRC );
            1;
        } or do {
            $pod = decode( 'cp1252', $raw_pod );
        };
    }
    else {
        $pod = $c->req->parameters->{pod} // q{};
    }

    my $pod_data = $c->model('API::Pod')->pod2html(
        $pod,
        {
            show_errors => 1,
        }
    )->get;
    my $html  = $pod_data->{pod_html}  // q{};
    my $index = $pod_data->{pod_index} // q{};

    my $results = {
        pod       => $pod,
        pod_html  => $html,
        pod_index => $index,
        pod_name  => $pod_data->{pod_name},
        abstract  => $pod_data->{abstract},
    };
    if ( $c->req->parameters->{raw} ) {
        $c->res->content_type('text/html');
        $c->res->body( '<nav class="toc">' . $index . '</nav>' . $html );
        $c->detach;
    }
    elsif ( $c->req->accepts('application/json') ) {
        $c->stash( {
            current_view => 'JSON',
            json         => $results,
        } );
    }
    else {
        $c->stash($results);
    }
}

__PACKAGE__->meta->make_immutable;

1;
