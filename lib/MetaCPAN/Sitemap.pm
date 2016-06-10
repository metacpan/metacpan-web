package MetaCPAN::Sitemap;

=head1 DESCRIPTION

Generate an XML file containing URLs use by the robots.txt Sitemap. We use this
module to generate one each for authors, modules and releases.

=cut

use strict;
use warnings;
use MetaCPAN::Moose;

use autodie;

use Carp;
use Search::Elasticsearch;
use File::Spec;
use MetaCPAN::Web::Types qw( HashRef Int Str );
use MooseX::StrictConstructor;
use PerlIO::gzip;
use XML::Simple qw(:strict);

has [ 'cpan_directory', 'object_type', 'field_name', 'xml_file', ] => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'filter' => (
    is  => 'ro',
    isa => HashRef,
);

has 'size' => (
    is  => 'ro',
    isa => Int,
);

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

sub process {
    my $self = shift;

    # Check that a) the directory where the output file wants to be does
    # actually exist and b) the directory itself is writeable.

    # Get started. Create the ES object and the scrolled search object.
    # XXX Remove this hardcoded URL
    my $es = Search::Elasticsearch->new(
        cxn_pool         => 'Static::NoPing',
        nodes            => ['api-v1.metacpan.org'],
        send_get_body_as => 'POST',
    );

    my $field_name = $self->field_name;

    # Start off with standard search parameters ..

    my %search_parameters = (
        index  => 'v0',
        size   => 5000,
        type   => $self->object_type,
        fields => [$field_name],
    );

    # ..and augment them if necesary.

    if ( $self->filter ) {

        # Copy the filter over wholesale into the search parameters, and add
        # the filter fields to the field list.

        $search_parameters{'body'}{'query'}{'match'} = $self->filter;
        push @{ $search_parameters{'fields'} }, keys %{ $self->filter };
    }

    my $scrolled_search = $es->scroll_helper(%search_parameters);

    # Open the output file, get ready to pump out the XML.

    open my $fh, '>:gzip', $self->xml_file;

    my @urls;
    my $metacpan_url = q{};
    if ( $self->cpan_directory ) {
        $metacpan_url
            = 'https://metacpan.org/' . $self->cpan_directory . q{/};
    }

    while ( $scrolled_search->refill_buffer ) {
        push @urls,
            map { $metacpan_url . $_->{'fields'}->{$field_name} }
            $scrolled_search->drain_buffer;
    }

    $_ = $_ . q{ } for @urls;

    $self->{size} = @urls;
    my $xml = XMLout(
        {
            'xmlns'     => 'http://www.sitemaps.org/schemas/sitemap/0.9',
            'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
            'xsi:schemaLocation' =>
                'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd',
            'url' => [ sort @urls ],
        },
        'KeyAttr'    => [],
        'RootName'   => 'urlset',
        'XMLDecl'    => q/<?xml version='1.0' encoding='UTF-8'?>/,
        'OutputFile' => $fh,
    );

    close $fh;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
