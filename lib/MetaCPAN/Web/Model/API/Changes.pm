package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Changes::Parser;
use Try::Tiny;

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( '/', @path ) );
}

sub last_version {
    my ( $self, $response, $release ) = @_;
    my $changes;
    if ( !exists $response->{content} or $response->{documentation} ) {
    } else {
        # I guess we have a propper changes file? :P
        try {
            $changes = MetaCPAN::Web::Model::API::Changes::Parser->load_string(
                $response->{content}
            );
        } catch {
            # we don't really care?
            warn "Error parsing changes: $_" if $ENV{CATALYST_DEBUG};
        };
    }
    return unless $changes;
    my @releases = $changes->releases;
    return unless scalar @releases;

    # Ok, lets make sure we get the right release..
    my $changelog = $self->find_changelog($release->{version}, \@releases);

    return unless $changelog;
    return $self->filter_release_changes($changelog, $release);
}

sub find_changelog {
    my ($self, $version, $releases) = @_;;

    foreach my $rel (@$releases) {
        return $rel if ($rel->version eq $version);
    }
}

sub filter_release_changes {
    my ($self, $changelog, $release) = @_;

    my ($bt, $bt_url);
    if ($release->{resources}->{bugtracker}) {
        $bt = $release->{resources}->{bugtracker};

        # should check for perldelta and github at least
        if ($bt->{web} and $bt->{web} =~ m|^https?://rt.cpan.org/|) {
            $bt = '_rt_cpan';
        } elsif ($bt->{web} and $bt->{web} =~ m|^https?://github.com/|) {
            $bt_url = $bt->{web};
            $bt = '_gh';
        } else {
            warn "unknown bt: " . dd $bt if $ENV{CATALYST_DEBUG};
            undef $bt;
        }
    } else {
        $bt = '_rt_cpan';
    }
    foreach my $g ($changelog->groups) {
        my $changes = $changelog->changes($g);
        my @new;
        foreach my $change (@$changes) {
            # lets call our filters.. this could be designed OPEN, instead of
            # CLOSED I guess..

            # We need to escape some html enteties here, since down the line we
            # disable it to get the links to work.. Copied from html filter in
            # Template::Alloy
            $change = do { local $_ = $change; s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/\"/&quot;/g; $_ };

            $change = $self->$bt($change, $bt_url) if $bt;
            push(@new, $change);
        }
        $changelog->set_changes( { group => $g }, @new);
    }
    return $changelog;
}

sub _rt_cpan {
    my ($self, $line) = @_;

    my $u = '<a href="https://rt.cpan.org/Ticket/Display.html?id=';
    # Stricter regex for -:
    $line =~ s{\b(RT[-:]?)(\d+)\b}{$u$2">$1$2</a>}gix;
    # A bit more relaxed here?
    $line =~ s{\b((?:RT)(?:\s*)[#])(\d+)\b}{$u$2">$1$2</a>}gx;

    # Some other cases
    $line =~ s{\b(bug\s+\#)(\d+)\b}{$u$2">$1$2</a>}gxi;

    return $line;
}

sub _gh {
    my ($self, $line, $bt) = @_;
    $bt =~ s|/$||;
    $line =~ s{((?:GH|)[#:-])(\d+)\b}{<a href="$bt/$2">$1$2</a>}gxi;
    return $line;
}
1;
