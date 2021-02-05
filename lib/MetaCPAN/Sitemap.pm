package MetaCPAN::Sitemap;
use strict;
use warnings;
use IO::Socket::SSL qw( SSL_VERIFY_PEER );
use IO::Async::Loop;
use IO::Async::SSL;
use Net::Async::HTTP;
use Cpanel::JSON::XS   ();
use IO::Compress::Gzip ();
use HTML::Entities qw( encode_entities_numeric );
use Future;

use Moo;

has api         => ( is => 'ro', required => 1 );
has url_prefix  => ( is => 'ro', required => 1 );
has object_type => ( is => 'ro', required => 1 );
has field_name  => ( is => 'ro', required => 1 );
has filter      => ( is => 'ro' );
has size        => ( is => 'ro',   default => 1000 );
has loop        => ( is => 'lazy', default => sub { IO::Async::Loop->new } );
has ua          => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        my $http = Net::Async::HTTP->new(
            user_agent =>
                'MetaCPAN-Web/1.0 (https://github.com/metacpan/metacpan-web)',
            max_connections_per_host => 5,
            SSL_verify_mode          => SSL_VERIFY_PEER,
            timeout                  => 10,
        );
        $self->loop->add($http);
        $http;
    }
);

sub DEMOLISH {
    $_[0]->ua->remove_from_parent;
}

# Mandatory arguments to this function are
# [] search object_type (author and release)
# [] result field_name (pauseid and distribution)
# [] name of output xml_file (path to the output XML file)
# Optional arguments to this function are
# [] output cpan_directory (author and release)
# [] test_search (search count - if non-zero, limits search to that number of
# items for testing)
# [] filter - contains filter for a field that also needs to be included in
# the list of form fields.

my $json = Cpanel::JSON::XS->new->utf8->canonical;

sub _request {
    my ( $self, $content, $cb ) = @_;
    my $url          = $self->api . '/';
    my $content_type = 'text/plain';
    if ( ref $content ) {
        $url .= $self->object_type . '/';
        $content_type = 'application/json';
        $content      = $json->encode($content);
    }
    $url .= '_search/scroll?scroll=1m&size=' . $self->size;
    $self->ua->POST( $url, $content, content_type => $content_type, )
        ->then( sub {
        my $response = shift;
        my $content  = $json->decode( $response->content );
        return Future->done
            if !@{ $content->{hits}{hits} };
        $cb->( $content->{hits}{hits} );
        return $self->_request( $content->{_scroll_id}, $cb );
        } );
}

sub write {
    my ( $self, $file ) = @_;

    my $fh = IO::Compress::Gzip->new( $file . '.new' );
    $fh->print(<<'END_XML_HEADER');
<?xml version='1.0' encoding='UTF-8'?>
<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
END_XML_HEADER

    $self->_request(
        {
            fields => [ $self->field_name ],
            query  => { match_all => {} },
            ( $self->filter ? ( filter => $self->filter ) : () ),
            sort => [ $self->field_name ],
        },
        sub {
            my $hits = shift;
            for my $hit (@$hits) {
                my $link_field = $hit->{fields}{ $self->field_name };
                $link_field = $link_field->[0] if ref $link_field;
                my $url = $self->url_prefix . $link_field;
                $fh->print( "    <url><loc>"
                        . encode_entities_numeric($url)
                        . "</loc></url>\n" );
            }
        }
    )->get;
    $fh->print("</urlset>\n");
    $fh->close;
    rename "$file.new", "$file";
    return;
}

1;
__END__

=head1 DESCRIPTION

Generate an XML file containing URLs use by the robots.txt Sitemap. We use this
module to generate one each for authors, modules and releases.

=cut
