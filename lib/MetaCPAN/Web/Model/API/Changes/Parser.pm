package MetaCPAN::Web::Model::API::Changes::Parser;

use Moose;
use version qw();

extends 'CPAN::Changes';


override 'load_string' => sub {
    my ( $class, $string, @args ) = @_;

    my $changes  = $class->new( @args );
    my $preamble = '';
    my ( @releases, $ingroup, $indent, $spec_groups);

    $string =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;
    my @lines = split( "\n", $string );

    my $version_line_re
        = $changes->{ next_token }
        ? qr/^(?:$version::LAX|$changes->{next_token})/
        : qr/^$version::LAX/;

    $preamble .= shift( @lines ) . "\n" while @lines && $lines[ 0 ] !~ $version_line_re;

    for my $l ( @lines ) {

        # Version & Date
        if ( $l =~ $version_line_re ) {
            my ( $v, $n ) = split m{\s+}, $l, 2;
            my $match = '';
            my $d;

            # munge date formats, save the remainder as note
            if ( $n ) {
                # unknown dates
                if ( $n =~ m{^($CPAN::Changes::UNKNOWN_VALS)}i ) {
                    $d     = $1;
                    $match = $d;
                }
                # handle localtime-like timestamps
                elsif ( $n
                    =~ m{^(\D{3}\s+(\D{3})\s+(\d{1,2})\s+([\d:]+)?\D*(\d{4}))} )
                {
                    $match = $1;
                    if ( $4 ) {

                        # unfortunately ignores TZ data
                        $d = sprintf(
                            '%d-%02d-%02dT%sZ',
                            $5, $changes->{ months }->{ $2 },
                            $3, $4
                        );
                    }
                    else {
                        $d = sprintf( '%d-%02d-%02d',
                            $5, $changes->{ months }->{ $2 }, $3 );
                    }
                }

                # RFC 2822
                elsif ( $n
                    =~ m{^(\D{3}, (\d{1,2}) (\D{3}) (\d{4}) (\d\d:\d\d:\d\d) ([+-])(\d{2})(\d{2}))}
                    )
                {
                    $match = $1;
                    $d = sprintf(
                        '%d-%02d-%02dT%s%s%02d:%02d',
                        $4, $changes->{ months }->{ $3 },
                        $2, $5, $6, $7, $8
                    );
                }

                # handle dist-zilla style, again ingoring TZ data
                elsif ( $n
                    =~ m{^((\d{4}-\d\d-\d\d)\s+(\d\d:\d\d(?::\d\d)?)(?:\s+[A-Za-z]+/[A-Za-z_-]+))} )
                {
                    $match = $1;
                    $d = sprintf( '%sT%sZ', $2, $3 );
                }

                # start with W3CDTF, ignore rest
                elsif ( $n =~ m{^($CPAN::Changes::W3CDTF_REGEX)}p ) {
                    $match = ${^MATCH};
                    $d = $match;
                    $d =~ s{ }{T};
                    # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
                    $d .= 'Z' if length( $d ) == 16 || length( $d ) == 19 || $d =~ m{\.\d+$};
                }

                # clean date from note
                $n =~ s{^$match\s*}{};
            }

            push @releases,
                CPAN::Changes::Release->new(
                version      => $v,
                date         => $d,
                _parsed_date => $match,
                note         => $n,
                );
            $ingroup = undef;
            $indent  = undef;
            next;
        }

        # Grouping
        if ( $l =~ m{^\s+\[\s*(.+?)\s*(\])\s*$}
                or (not $spec_groups and $l =~ m{^\s+\*\s*(.+?)\s*$})
        ) {
            $spec_groups++ if $2;
            $ingroup = $1;
            $releases[ -1 ]->add_group( $1 );
            next;
        }

        $ingroup = '' if !defined $ingroup;

        next if $l =~ m{^\s*$};

        if ( !defined $indent ) {
            $indent
                = $l =~ m{^(\s+)}
                ? '\s' x length $1
                : '';
        }

        $l =~ s{^$indent}{};

        # Inconsistent indentation between releases
        if ( $l =~ m{^\s} && !@{ $releases[ -1 ]->changes( $ingroup ) } ) {
            $l =~ m{^(\s+)};
            $indent = $1;
            $l =~ s{^\s+}{};
        }

        # Change line cont'd
        if ( $l =~ m{^\s} ) {
            $l =~ s{^\s+}{};
            # Change line is a nested change (DBIx-Class et al)
            if ( $l =~ m{^[-*+]\s} ) {
                # just add it as a new change, but keep the marker there?
                $releases[ -1 ]->add_changes( { group => $ingroup }, $l );
            } else {
                # This is continuation of last change?
                my $changeset = $releases[ -1 ]->changes( $ingroup );
                $changeset->[ -1 ] .= " $l";
            }
        }

        # Start of Change line
        else {
            $l =~ s{^[^[:alnum:]]+\s}{};    # remove leading marker
            $releases[ -1 ]->add_changes( { group => $ingroup }, $l );
        }

    }

    $changes->preamble( $preamble );
    $changes->releases( @releases );

    return $changes;
};
