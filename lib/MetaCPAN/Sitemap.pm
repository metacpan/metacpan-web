package MetaCPAN::Sitemap;

#  Generate an XML file containing URLs use by the robots.txt Sitemap. We
#  use this module to generate one each for authors, modules and releases.

use strict;
use warnings;
use Carp;

use File::Spec;
use ElasticSearch;
use PerlIO::gzip;
use XML::Simple qw(:strict);

#  Mandatory arguments to this function are
#  [] search objectType (author, distribution, and release)
#  [] result fieldName (pauseid, name, and download_url)
#  [] name of output xmlFile (path to the output XML file)
#  Optional arguments to this function are
#  [] output cpanDirectory (author, module, and doesn't exist)
#  [] testSearch (search count - if non-zero, limits search to that number of
#  items for testing)
#  [] filter - contains filter for a field that also needs to be included in
#  the list of form fields.

sub process {

    my ($args) = @_;
    my (%argKeys) = map { $_ => 1 } keys %{$args};

    my @required = qw/objectType fieldName xmlFile/;
    my @optional = qw/cpanDirectory testSearch filter/;

    #  Make sure none of the mandatory arguments are missing.

    my @missing;
    foreach my $field (@required) {
        if ( exists $args->{$field} ) {
            delete $argKeys{$field};
        }
        else {
            push( @missing, $field );
        }
    }
    if (@missing) {
        croak "Missing the following arguments: " . join( ', ', @missing );
    }

    #  Look for optional arguments, and see if there are any other arguments
    #  that were submitted that we weren't expecting.

    my @unexpected;
    foreach my $field (@optional) {
        if ( exists $args->{$field} ) {
            delete $argKeys{$field};
        }
        else {
            push( @unexpected, $field );
        }
    }
    if ( keys %argKeys ) {
        croak "Unexpected arguments: " . join( ', ', keys %argKeys );
    }

    #  Check that a) the directory where the output file wants to be does
    #  actually exist and b) the directory itself is writeable.

    my ( undef, $dir, $file ) = File::Spec->splitpath( $args->{'xmlFile'} );
    -d $dir or croak "$dir is not a directory";
    -w $dir or croak "$dir is not writeable";

    #  Get started. Create the ES object and the scrolled search object.

    my $es = ElasticSearch->new(
        servers    => 'api.metacpan.org',
        no_refresh => 1,
    );
    defined $es or croak "Unable to create ElasticSearch: $!";

    my $searchSize
        = ( exists $args->{'testSearch'} ? $args->{'testSearch'} : 5000 );

    #  Start off with standard search parameters ..

    my %searchParameters = (
        index  => 'v0',
        size   => $searchSize,
        type   => $args->{'objectType'},
        fields => [ $args->{'fieldName'} ],
    );

    #  ..and augment them if necesary.

    if ( exists $args->{'filter'} ) {

	#  Copy the filter over wholesale into the search parameters, and add
	#  the filter fields to the field list.

        $searchParameters{'queryb'} = $args->{'filter'};
        push( @{ $searchParameters{'fields'} }, keys %{ $args->{'filter'} } );
    }

    my $scrolledSearch = $es->scrolled_search(%searchParameters);

    #  Open the output file, get ready to pump out the XML.

    open( my $xmlFH, '>:gzip', $args->{'xmlFile'} )
        or croak "Unable to open $args->{'xmlFile'}: $!";

    my @urls;
    my $metaCPANurl = '';
    if ( exists $args->{'cpanDirectory'} ) {
        $metaCPANurl = "https://metacpan.org/$args->{'cpanDirectory'}/";
    }

    do {
        my @hits = $scrolledSearch->drain_buffer;
        push( @urls,
            map {"$metaCPANurl$_->{'fields'}{ $args->{'fieldName'} }"}
                @hits );
    } while ( !exists $args->{'testSearch'} && $scrolledSearch->next() );

    my $xml = XMLout(
        {   'xmlns'     => "http://www.sitemaps.org/schemas/sitemap/0.9",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' =>
                "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd",
            'url' => \@urls,
        },
        'KeyAttr'    => [],
        'RootName'   => 'urlset',
        'XMLDecl'    => q/<?xml version='1.0' encoding='UTF-8'?>/,
        'OutputFile' => $xmlFH,
    );

    close($xmlFH);
}

1;

