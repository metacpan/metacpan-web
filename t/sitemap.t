use strict;
use warnings;

use Test::More;
use Try::Tiny;
use File::Temp qw/ tempfile /;
use XML::Simple;

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
                objectType    => 'author',
                fieldName     => 'pauseid',
                xmlFile       => '',
                cpanDirectory => 'author',
            },
            pattern => qr{https:.+/author/[A-Z-]+},
        },

        {   inputs => {
                objectType    => 'distribution',
                fieldName     => 'name',
                xmlFile       => '',
                cpanDirectory => 'module',
            },
            pattern => qr{https:.+/module/\w+},
        },

        {   inputs => {
                objectType => 'release',
                fieldName  => 'download_url',
                xmlFile    => '',
		filter     => { status => 'latest' },
            },
            pattern =>
                qr{https?:.+authors/id/[A-Z]/[A-Z][A-Z]/[A-Z0-9-]+/.+\.(tar\.gz|tgz|zip|bz2)},
        }
    );

    my $searchSize = 250;
    foreach my $test (@tests) {

        #  Before doing the real tests, try removing each one of the required
        #  input arguments, and confirm that that this intentional error is
        #  caught. (This list is the same as the 'required' list in the module
        #  that we're testing.)

        for my $argToDelete (qw/objectType fieldName xmlFile/) {

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
            $bogusArgs{'xmlFile'} = $bogusXMLfile;

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

        #  Generate the XML file into a temporary file, then check that the
        #  file exists, is valid XML, and has the right number of URLs.

        my $args = $test->{'inputs'};
        $args->{'testSearch'} = $searchSize;
        ( undef, $args->{'xmlFile'} ) = tempfile();

        MetaCPAN::Sitemap::process($args);
        ok( -e $args->{'xmlFile'},
            "XML output file for $args->{'objectType'} exists" );

        my $xml = XMLin( $args->{'xmlFile'} );
        ok( defined $xml, "XML for $args->{'objectType'} checks out" );

        ok( @{ $xml->{'url'} }, "We have some URLs to look at" );
        is( $searchSize,
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

