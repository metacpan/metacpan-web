package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use CPAN::Changes;
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
            $changes = CPAN::Changes->load_string($response->{content});
        } catch {
            # we don't really care?
            warn "Error parsing changes: $_" if $ENV{CATALYST_DEBUG};
        };
    }
    return unless $changes;
    my @releases = $changes->releases;
    return unless scalar @releases;

    return $self->filter_release_changes($releases[-1], $release);
}


sub filter_release_changes {
    my ($self, $changelog, $release) = @_;

    use Data::Dump;
    my $bt;
    if ($release->{resources}->{bugtracker}) {
        $bt = $release->{resources}->{bugtracker};

        # should check for perldelta and github at least
        if ($bt->{web} and $bt->{web} =~ m|^https?://rt.cpan.org/|) {
            $bt = '_rt_cpan';
        } else {
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

            $change = $self->$bt($change) if $bt;
            push(@new, $change);
        }
        $changelog->set_changes( { group => $g }, @new);
    }
    return $changelog;
}

sub _rt_cpan {
    my ($self, $line) = @_;

    $line =~ s{\b(RT(?:\s)?[#:-])(\d*)\b}{<a href="https://rt.cpan.org/Ticket/Display.html?id=$2">$1$2</a>}gx;

    return $line;
}
1;
