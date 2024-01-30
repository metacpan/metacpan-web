package MetaCPAN::Web::Model::API::Pod;
use Moose;
use namespace::autoclean;

use MetaCPAN::Web::RenderUtil qw( split_index filter_html );
use Encode                    qw( encode );
use Future                    ();

extends 'MetaCPAN::Web::Model::API';

sub file_pod {
    my ( $self, $file, $opts ) = @_;

    $opts ||= {};

    my $pod_path
        = '/pod/'
        . ( $file->{assoc_pod}
            || "$file->{author}/$file->{release}/$file->{path}" );

    return $self->request(
        $pod_path,
        undef,
        {
            show_errors => 1,
            ( $opts->{permalinks} ? ( permalinks => 1 ) : () ),
            url_prefix => '/pod/',
        }
    )->then( $self->_with_filter );
}

sub pod2html {
    my ( $self, $pod, $opts ) = @_;

    $opts ||= {};

    return Future->done( {} )
        if !length $pod;
    return $self->request(
        'pod_render',
        undef,
        {
            pod => encode( 'UTF-8', $pod ),
            %$opts,
        },
        'POST'
    )->then( $self->_with_filter )->then( sub {
        my $data = shift;

        if ( my $html = $data->{pod_html} ) {
            my $p = HTML::TokeParser->new( \$html );
            while ( my $t = $p->get_token ) {
                my ( $type, $tag, $attr ) = @$t;
                next
                    unless ( $type eq 'S'
                    && $tag eq 'h1'
                    && $attr->{id}
                    && $attr->{id} eq 'NAME' );

                my $name_section = $p->get_trimmed_text('h1') or next;
                if ( $name_section =~ /(?:NAME\s+)?([^-]+?)\s*-\s*(.*)/s ) {
                    $data->{pod_name} = "$1";
                    $data->{abstract} = "$2";
                    last;
                }
            }
        }

        Future->done($data);
    } );
}

sub _with_filter {
    my ($self) = @_;
    sub {
        my $data = shift;
        if ( my $raw = $data->{raw} ) {
            my ( $index, $body ) = split_index($raw);
            $data->{pod_index}
                = filter_html( $index, $data->{path} ? $data : () );
            $data->{pod_html}
                = filter_html( $body, $data->{path} ? $data : () );
        }
        return Future->done($data);
    };
}

__PACKAGE__->meta->make_immutable;

1;

