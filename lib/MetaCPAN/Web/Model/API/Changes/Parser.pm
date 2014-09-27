package MetaCPAN::Web::Model::API::Changes::Parser;

use Moose;
use version qw();

use CPAN::Changes;
my %months;
my $m = 0;
$months{$_} = ++$m for qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

sub load {
    my ( $class, $file ) = @_;
    open my $fh, '<', $file
        or die "can't open $file: $!";
    my $content = do { local $/; <$fh> };
    $class->parse($content);
}

sub parse {
    my ( $class, $string ) = @_;

    my @lines = split /\r\n?|\n/, $string;

    my $preamble = q{};
    my @releases;
    my $release;
    my @indents;
    for my $linenr ( 0 .. $#lines ) {
        my $line = $lines[$linenr];
        if ( $line =~ /^(?:version\s+)?($version::LAX)(\s+(.*))?$/i ) {
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
                if ( $note =~ s{^($CPAN::Changes::UNKNOWN_VALS)}{}i ) {
                    $date = $1;
                }

                # handle localtime-like timestamps
                elsif ( $note
                    =~ s{^\D{3}\s+(\D{3})\s+(\d{1,2})\s+([\d:]+)?\D*(\d{4})}{}
                    )
                {
                    if ($3) {

                        # unfortunately ignores TZ data
                        $date = sprintf( '%d-%02d-%02dT%sZ',
                            $4, $months{$1}, $2, $3 );
                    }
                    else {
                        $date
                            = sprintf( '%d-%02d-%02d', $4, $months{$1}, $2 );
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
                    =~ s{^(\d{4}-\d\d-\d\d)\s+(\d\d:\d\d(?::\d\d)?)(?:\s+[A-Za-z]+/[A-Za-z_-]+)}{}
                    )
                {
                    $date = sprintf( '%sT%sZ', $1, $2 );
                }

                # start with W3CDTF, ignore rest
                elsif ( $note =~ m{^($CPAN::Changes::W3CDTF_REGEX)} ) {
                    $date = $1;
                    $date =~ s{ }{T};

                    # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
                    $date .= 'Z'
                        if length($date) == 16
                        || length($date) == 19
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

1;
