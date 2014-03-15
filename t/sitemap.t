use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Try::Tiny;
use File::Temp qw/ tempdir /;
use XML::Simple;
use MetaCPAN::Sitemap;
use lib './lib';

BEGIN { use_ok('MetaCPAN::Sitemap'); }
{
    require_ok('MetaCPAN::Sitemap');

    #  A very simple check that calling the process routine with no arguments
    #  causes a croak result.

    try {
        MetaCPAN::Sitemap::process();
        BAIL_OUT('Did not fail with no arguments.');
    }
    catch {
        ok( 1, "Called with no arguments, caught error: $_" );
    };

   #  Test each of the three things that the production script is going to do,
   #  but limit the searches to a single chunk of 250 results to speed things
   #  along.

    my @tests = (

        {   inputs => {
                object_type    => 'author',
                field_name     => 'pauseid',
                xml_file       => '',
                cpan_directory => 'author',
            },
            pattern => qr{https:.+/author/[a-z0-9A-Z-]+},
        },

        {   inputs => {
                object_type    => 'distribution',
                field_name     => 'name',
                xml_file       => '',
                cpan_directory => 'pod',
            },
            pattern => qr{https:.+/pod/[.\a-zA-Z0-9_::|a-z0-9A-Z_::]+},
        },

        {   inputs => {
                object_type => 'release',
                field_name  => 'distribution',
                xml_file    => '',
		cpan_directory => 'release',
		filter     => { status => 'latest' },
            },
            pattern =>
                qr{https?:.+/release/[a-z0-9A-Z-]+},
        }
    );

   my $searchSize = 250;
   my $tempDir = tempdir( CLEANUP => 1 );

    foreach my $test (@tests) {

        #  Before doing the real tests, try removing each one of the required
        #  input arguments, and confirm that that this intentional error is
        #  caught. (This list is the same as the 'required' list in the module
        #  that we're testing.)

        for my $argToDelete (qw/object_type field_name xml_file/) {

            my (%bogusArgs) = %{ $test->{'inputs'} };
            delete $bogusArgs{$argToDelete};

            try {
                MetaCPAN::Sitemap::process( \%bogusArgs );
                BAIL_OUT('Did not fail with missing argument.');
            }
            catch {
                ok( 1, "Called with a missing argument, caught error: $_" );
            };
        }

        #  Add a bogus argument to the call, to make sure that error gets
        #  caught as well.

        for my $bogusArgument (qw/objecttype fieldname xmlfile/) {

            my (%bogusArgs) = %{ $test->{'inputs'} };
            $bogusArgs{$bogusArgument} = 'foo';

            try {
                MetaCPAN::Sitemap::process( \%bogusArgs );
                BAIL_OUT('Did not fail with bogus argument.');
            }
            catch {
                ok( 1,
                    "Called with an extra, bogus argument, caught error: $_"
                );
            };
        }

       #  Try a bogus directory, and then a directory that exists, but that we
       #  shouldn't be able to write to, to verify that the error-checking is
       #  behaving.

        for my $bogusXMLfile (qw{ /doesntExist123/foo.xml /usr/bin/foo.xml}) {

            my (%bogusArgs) = %{ $test->{'inputs'} };
            $bogusArgs{'xml_file'} = $bogusXMLfile;

            try {
                MetaCPAN::Sitemap::process( \%bogusArgs );
                BAIL_OUT('Did not fail with bad XML file path.');
            }
            catch {
                ok( 1,
                    "Called with a bogus XML filename argument, caught error: $_"
                );
            };
        }

	#  Generate the XML file into a file in a temporary directory, then
	#  check that the file exists, is valid XML, and has the right number
	#  of URLs.

        my $args = $test->{'inputs'};
        $args->{'size'} = $searchSize;
        $args->{'xml_file'} = File::Spec->catfile( $tempDir,"$test->{'inputs'}{'object_type'}.xml.gz" );

        MetaCPAN::Sitemap::process( $args );
        ok( -e $args->{'xml_file'},
            "XML output file for $args->{'object_type'} exists" );

        open( my $xmlFH, '<:gzip', $args->{'xml_file'} )
          or BAIL_OUT( "Unable to open $args->{'xml_file'}: $!" );
	
        my $xml = XMLin( $xmlFH );
        ok( defined $xml, "XML for $args->{'object_type'} checks out" );

        ok( @{ $xml->{'url'} }, "We have some URLs to look at" );
        is( $args->{'size'},
            scalar @{ $xml->{'url'} },
            "Number of URLs is correct"
        );

        #  Check that each of the urls has the right pattern.

        foreach my $url ( @{ $xml->{'url'} } ) {
            like( $url, $test->{'pattern'}, "URL matches" );
        }
    }

    done_testing;
}
