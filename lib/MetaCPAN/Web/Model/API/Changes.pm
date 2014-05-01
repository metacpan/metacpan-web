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
    }
    else {
        # I guess we have a propper changes file? :P
        try {
            $changes
                = MetaCPAN::Web::Model::API::Changes::Parser->load_string(
                $response->{content} );
        }
        catch {
            # we don't really care?
            warn "Error parsing changes: $_" if $ENV{CATALYST_DEBUG};
        };
    }
    return unless $changes;
    my @releases = $changes->releases;
    return unless scalar @releases;

    # Ok, lets make sure we get the right release..
    my $changelog = $self->find_changelog( $release->{version}, \@releases );

    return unless $changelog;
    return $self->filter_release_changes( $changelog, $release );
}

sub find_changelog {
    my ( $self, $version, $releases ) = @_;

    foreach my $rel (@$releases) {
        return $rel if ( $rel->version eq $version );
    }
}

my $rt_cpan_base = "https://rt.cpan.org/Ticket/Display.html?id=";
my $rt_perl_base = "https://rt.perl.org/Ticket/Display.html?id=";
my $sep = qr{[-:]|\s*[#]?};

sub _link_issues {
    my ($self, $change, $gh_base, $rt_base) = @_;
    $change =~ s{(
      (?:
        (
          \b(?:blead)?perl\s+(?:RT|bug)$sep
        |
          (?<=\[)(?:blead)?perl\s+$sep
        |
          \brt\.perl\.org\s+\#
        )
      |
        (
          \bCPAN\s+(?:RT|bug)$sep
        |
          (?<=\[)CPAN\s+$sep
        |
          \brt\.cpan\.org\s+\#
        )
      |
        (\bRT$sep)
      |
        (\b(?:GH|PR)$sep)
      |
        ((?:\bbug\s*)?\#)
      )
      (\d+)\b
    )}{
        my $text = $1;
        my $issue = $7;
        my $base
          = $2 ? $rt_perl_base
          : $3 ? $rt_cpan_base
          : $4 ? $rt_base
          : $5 ? $gh_base
          # this form is non-specific, so guess based on issue number
          : ($gh_base && $issue < 10000)
                ? $gh_base
                : $rt_base
        ;
        $base ? qq{<a href="$base$issue">$text</a>} : $text;
    }xgei;

    return $change;
}

sub filter_release_changes {
    my ( $self, $changelog, $release ) = @_;

    my $gh_base;
    my $rt_base;
    my $bt = $release->{resources}{bugtracker} && $release->{resources}{bugtracker}{web};
    my $repo = $release->{resources}{repository};
    $repo = ref $repo ? $repo->{url} : $repo;
    if ( $bt && $bt =~ m|^https?://github\.com/| ) {
        $gh_base = $bt;
        $gh_base =~ s{/*$}{/};
    }
    elsif ($repo && $repo =~ m|\bgithub\.com/([^/]+/[^/]+)| ) {
        my $name = $1;
        $name =~ s/\.git$//;
        $gh_base = "https://github.com/$name/issues/";
    }
    if ( $bt && $bt =~ m|\brt\.perl\.org\b| ) {
        $rt_base = $rt_perl_base;
    }
    else {
        $rt_base = $rt_cpan_base;
    }

    foreach my $g ( $changelog->groups ) {
        my $changes = $changelog->changes($g);
        my @new;
        foreach my $change (@$changes) {

            # lets call our filters.. this could be designed OPEN, instead of
            # CLOSED I guess..

           # We need to escape some html enteties here, since down the line we
           # disable it to get the links to work.. Copied from html filter in
           # Template::Alloy
            for ($change) {
                s/&/&amp;/g;
                s/</&lt;/g;
                s/>/&gt;/g;
                s/"/&quot;/g;
            }
            push( @new, $self->_link_issues($change, $gh_base, $rt_base) );
        }
        $changelog->set_changes( { group => $g }, @new );
    }
    return $changelog;
}

1;
