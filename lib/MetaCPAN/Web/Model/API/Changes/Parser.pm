package MetaCPAN::Web::Model::API::Changes::Parser;

use Moose;
use version qw();

my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my %months = map +( $months[$_] => $_ ), 0 .. $#months;
my $months = join '|', @months;

our $W3CDTF_REGEX = qr{
    (\d\d\d\d) # Year
    (?:
        [-/](\d\d|$months) # -Month
        (?:
            [-/](\d\d) # -Day
            (?:
                [T\s]
                (\d\d):(\d\d) # Hour:Minute
                (?:
                    :(\d\d)     # :Second
                    (\.\d+)?    # .Fractional_Second
                )?
                (
                    Z          # UTC
                    | [+-]\d\d:\d\d    # Hour:Minute TZ offset
                      (?::\d\d)?       # :Second TZ offset
                )?
            )?
        )?
    )?
}x;

our $UNKNOWN_VALS = join(
    '|',
    (
        'Unknown Release Date',
        'Unknown',
        'Not Released',
        'Development Release',
        'Development',
        'Developer Release',
    )
);

sub load {
    my ( $class, $file ) = @_;
    open my $fh, '<', $file
        or die "can't open $file: $!";
    my $content = do { local $/; <$fh> };
    $class->parse($content);
}

sub parse {
    my ( undef, $string ) = @_;

    my @lines = split /\r\n?|\n/, $string;

    my $preamble = q{};
    my @releases;
    my $release;
    my @indents;
    for my $linenr ( 0 .. $#lines ) {
        my $line = $lines[$linenr];
        if ( $line
            =~ /^(?:version\s+)?($version::LAX(?:-TRIAL)?)(\s+(.*))?$/i )
        {
            my $version = $1;
            my $note    = $3;
            if ($note) {
                $note =~ s/^[\W\s]+//;
                $note =~ s/\s+$//;
            }
            my $date;

            # munge date formats, save the remainder as note
            if ($note) {

                # unknown dates
                if ( $note =~ s{^($UNKNOWN_VALS)}{}i ) {
                    $date = $1;
                }

    # handle localtime-like timestamps
    # May Tue 03 17:25:00 2005
    # /changes/distribution/Catalyst-View-PSP
    #
    # Thu Nov 19 09:25:53 2009
    # /changes/distribution/GO-TermFinder
    #
    # Sun Jan  29 2012
    # /changes/distribution/Scalar-Constant
    #
    # Sun Mar  0 11:40 2014 (AMS time)
    # /release/YVES/Sereal-Encoder-3.000_004
    # XXX haarg is going to rip this out and replace it with something better.
                elsif ( $note
                    =~ s{^(\D{3})\s+(\D{3})\s+(\d{1,2})\s+([\d:]+)?\D*(\d{4})}{}
                    )
                {
                    my @m     = @{^CAPTURE};
                    my $month = $months{$1} || $months{$2};
                    if ( $month && !grep +( !defined || /[^\d:]/ ),
                        @m[ 2 .. 4 ] )
                    {

                        # unfortunately ignores TZ data
                        $date = sprintf( '%d-%02d-%02dT%sZ',
                            $m[4], $month, $m[2], $m[3] );
                    }
                    elsif ( $month && $m[1] && $m[3] ) {
                        $date
                            = sprintf( '%d-%02d-%02d', $m[3], $month, $m[1] );
                    }
                    else {
                        $note = join q{ }, grep {defined} @m, $note;
                    }
                }

                # RFC 2822
                elsif ( $note
                    =~ s{^\D{3}, (\d{1,2}) (\D{3}) (\d{4}) (\d\d:\d\d:\d\d) ([+-])(\d{2})(\d{2})}{}
                    )
                {
                    $date = sprintf( '%d-%02d-%02dT%s%s%02d:%02d',
                        $3, $months{$2}, $1, $4, $5, $6, $7 );
                }

                # handle dist-zilla style, again ingoring TZ data
                elsif ( $note
                    =~ s{^(\d{4}-\d\d-\d\d)\s+(\d\d:\d\d)(?::(\d\d))?(?:\s+[A-Za-z]+/[A-Za-z_-]+)}{}
                    )
                {
                    $date = sprintf( '%sT%s:%02dZ', $1, $2, $3 // 0 );
                }

                # start with W3CDTF, ignore rest
                elsif ( $note =~ s{^($W3CDTF_REGEX)}{} && defined $3 ) {
                    $date = $1;
                    my $month = $3;
                    if ( $month =~ /\D/ ) {
                        $date =~ s{$month}{sprintf "%02d", $months{$month}}e;
                    }
                    $date =~ s{/}{-}g;
                    $date =~ s{ }{T};

                    # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
                    if ( length($date) == 16 ) {
                        $date .= ':00';
                    }

                    $date .= 'Z'
                        if length($date) == 19
                        || $date =~ m{\.\d+$};
                }

                # clean date from note
                $note =~ s{^\s+}{};
            }
            $release = {
                version => $version,
                date    => $date,
                note    => $note,
                entries => [],
                line    => $linenr,
            };
            push @releases, $release;
            @indents = ($release);
        }
        elsif (@indents) {
            if ( $line =~ /^[-_*+~#=\s]*$/ ) {
                $indents[-1]{done}++
                    if @indents > 1;
                next;
            }
            $line =~ s/\s+$//;
            $line =~ s/^(\s*)//;
            my $indent = 1 + length _expand_tab($1);
            my $change;
            my $done;
            my $nest;
            if ( $line =~ /^\[\s*([^\[\]]*)\]$/ ) {
                $done   = 1;
                $nest   = 1;
                $change = $1;
                $change =~ s/\s+$//;
            }
            elsif ( $line =~ /^[-*+=#]+\s+(.*)/ ) {
                $change = $1;
            }
            else {
                $change = $line;
                if (   $indent >= $#indents
                    && $indents[-1]{text}
                    && !$indents[-1]{done} )
                {
                    $indents[-1]{text} .= " $change";
                    next;
                }
            }

            my $group;
            my $nested;

            if ( !$nest && $indents[$indent]{nested} ) {
                $nested = $group = $indents[$indent]{nested};
            }
            elsif ( !$nest && $indents[$indent]{nest} ) {
                $nested = $group = $indents[$indent];
            }
            else {
                ($group)
                    = grep {defined} reverse @indents[ 0 .. $indent - 1 ];
            }

            my $entry = {
                text   => $change,
                line   => $linenr,
                done   => $done,
                nest   => $nest,
                nested => $nested,
            };
            push @{ $group->{entries} ||= [] }, $entry;

            if ( $indent <= $#indents ) {
                $#indents = $indent;
            }

            $indents[$indent] = $entry;
        }
        elsif (@releases) {

            # garbage
        }
        else {
            $preamble .= "$line\n";
        }
    }
    $preamble =~ s/^\s*\n//;
    $preamble =~ s/\s+$//;
    my @entries = @releases;
    while ( my $entry = shift @entries ) {
        push @entries, @{ $entry->{entries} } if $entry->{entries};
        delete @{$entry}{qw(done nest nested)};
    }
    return {
        preamble => $preamble,
        releases => [ reverse @releases ],
    };
}

sub _expand_tab {
    my $string = "$_[0]";
    $string =~ s/([^\t]*)\t/$1 . (" " x (8 - (length $1) % 8))/eg;
    return $string;
}

__PACKAGE__->meta->make_immutable;

1;
