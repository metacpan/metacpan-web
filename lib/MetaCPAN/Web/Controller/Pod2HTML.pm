package MetaCPAN::Web::Controller::Pod2HTML;

use Moose;

use Encode                    qw( decode DIE_ON_ERR encode LEAVE_SRC );
use HTML::TokeParser          ();
use MetaCPAN::Web::RenderUtil qw( filter_html split_index );
use Future                    ();

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub render_pod {
    my ( $c, $pod ) = @_;
    return Future->done( {} )
        if !length $pod;
    my $html = $c->model('API')->request(
        'pod_render',
        undef,
        {
            pod         => encode( 'UTF-8', $pod ),
            show_errors => 1,
        },
        'POST'
    )->then( sub {
        my ( $index, $pod ) = split_index( $_[0]->{raw} );
        $_ = filter_html($_) for ( $index, $pod );
        Future->done( {
            pod       => $pod,
            pod_index => $index,
        } );
    } );
}

sub pod2html : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $pod;
    if ( my $pod_file = $c->req->upload('pod_file') ) {
        my $raw_pod = $pod_file->slurp;
        eval {
            $pod = decode( 'UTF-8', $raw_pod, DIE_ON_ERR | LEAVE_SRC );
            1;
        } or $pod = decode( 'cp1252', $raw_pod );
    }
    else {
        $pod = $c->req->parameters->{pod} // q{};
    }

    my $pod_data = render_pod($pod)->get;
    my $html     = $pod_data->{pod} // q{};

    if ( $c->req->parameters->{raw} ) {
        $c->res->content_type('text/html');
        $c->res->body($html);
        $c->detach;
    }
    elsif ( $c->req->accepts('application/json') ) {
        $c->stash( { current_view => 'JSON' } );
    }

    $c->stash( {
        pod          => $pod,
        pod_rendered => $html,
        pod_index    => $pod_data->{pod_index},
        ( length $html ? %{ pod_info($html) } : () ),
    } );
}

sub pod_info {
    my $p = HTML::TokeParser->new( \( $_[0] ) );
    while ( my $t = $p->get_token ) {
        my ( $type, $tag, $attr ) = @$t;
        next
            unless ( $type eq 'S'
            && $tag eq 'h1'
            && $attr->{id}
            && $attr->{id} eq 'NAME' );

        my $name_section = $p->get_trimmed_text('h1') or next;
        if ( $name_section =~ /(?:NAME\s+)?([^-]+?)\s*-\s*(.*)/s ) {
            return {
                pod_name => "$1",
                abstract => "$2",
            };
        }
    }
    return {};
}

__PACKAGE__->meta->make_immutable;

1;
