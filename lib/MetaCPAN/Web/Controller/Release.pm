package MetaCPAN::Web::Controller::Release;

use Moose;
use Future;

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub root : Chained('/') PathPart('release') CaptureArgs(2) {
    my ( $self, $c, $author, $release ) = @_;

    # force consistent casing in URLs
    if ( $author ne uc($author) ) {

        $c->browser_max_age('1y');
        $c->cdn_max_age('1y');

        my @captures = @{ $c->req->captures };
        $captures[0] = uc $author;

        $c->res->redirect(
            $c->uri_for(
                $c->action,               \@captures,
                @{ $c->req->final_args }, $c->req->params,
            ),
            301
        );
        $c->detach;
    }

    $c->stash( {
        author_name  => $author,
        release_name => $release,
    } );
}

sub release_view : Chained('root') PathPart('') Args(0) {
    my ( $self,   $c )       = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->stash(
        permalinks   => 1,
        release_info => $c->model( 'ReleaseInfo', full_details => 1 )
            ->get( $author, $release ),
    );
    $c->forward('view');
}

sub view : Private {
    my ( $self, $c ) = @_;

    my $release_info = $c->stash->{release_info};

    my $data = $release_info->else( sub {
        my $error = shift;
        return Future->fail($error)
            if !ref $error;
        $c->detach('/not_found')
            if $error->{code} == 404;
        $c->detach( '/internal_error', $error );
    } )->get;

    my $release = $data->{release};

    $c->browser_max_age('1h');
    $c->res->last_modified( $release->{date} );
    $c->cdn_max_age('1y');
    $c->add_dist_key( $release->{distribution} );
    $c->add_author_key( $release->{author} );

    my $categories = $self->_files_to_categories( map @$_, grep defined,
        $data->{files}, $data->{modules} );

    my @changes = _link_issue_changelogs( $release, @{ $data->{changes} } );

    $c->stash(
        %$data,
        %$categories,
        changes => \@changes,

        template => 'release.tx',

        # TODO: Put this in a more general place.
        # Maybe make a hash for feature flags?
        (
            map { ( $_ => $c->config->{$_} ) }
                qw( mark_unauthorized_releases )
        ),
    );
}

my %module_field_map = (
    (
        map +( $_ => $_ ),
        qw(authorized indexed version associated_pod version_numified)
    ),
    name => 'module_name',
);

sub _files_to_categories {
    my $self  = shift;
    my %files = map +( $_->{path} => $_ ), @_;

    my $ret = +{
        provides      => [],
        documentation => [],
        modules       => [],
        other         => [],
        examples      => [],
    };

    for my $path ( sort keys %files ) {
        my $f = $files{$path};
        next
            if $f->{skip};
        my $path    = $f->{path};
        my @modules = @{ $f->{module} || [] };

        for my $module (@modules) {
            my $assoc = $module->{associated_pod}
                or next;
            $assoc =~ s{^\Q$f->{author}/$f->{release}/}{};
            next
                if $assoc eq $f->{path}
                || $assoc ne $f->{path} =~ s{\.pm$}{\.pod}r;

            my $assoc_file = $files{$assoc}
                or next;

            $f->{$_} ||= $assoc_file->{$_} for qw(
                abstract
                documentation
            );
            $assoc_file->{skip}++;
        }

        if (@modules) {
            my %s;
            if ( $f->{documentation} ) {
                push @{ $ret->{modules} }, $f;
                $s{ $f->{documentation} }++;
            }

            push @{ $ret->{provides} }, grep !$s{ $_->{module_name} }++, map {
                ;
                my $entry = {%$f};
                my $m     = $_;
                $entry->{ $module_field_map{$_} } = $m->{$_}
                    for grep exists $m->{$_}, keys %module_field_map;
                $entry;
            } @modules;
        }
        elsif ( $f->{documentation} && $path =~ m/\.pm$/ ) {
            push @{ $ret->{modules} }, $f;
        }
        elsif ( $path =~ m{^(?:eg|ex|examples?|samples?)\b}i ) {
            push @{ $ret->{examples} }, $f;
        }
        elsif ( $f->{documentation} ) {
            push @{ $ret->{documentation} }, $f;
        }
        elsif ( $path =~ m/\.pm$/ ) {
            push @{ $ret->{modules} }, $f;
        }
        elsif ( $path =~ m{(?:eg|ex|examples?|samples?)\b}i ) {
            push @{ $ret->{examples} }, $f;
        }
        elsif ( $path =~ m/\.pod$/ ) {
            push @{ $ret->{documentation} }, $f;
        }
        else {
            push @{ $ret->{other} }, $f;
        }
    }

    $ret->{provides} = [
        sort {
                   $a->{module_name} cmp $b->{module_name}
                || $a->{path} cmp $b->{path}
        } @{ $ret->{provides} }
    ];

    return $ret;
}

my $rt_cpan_base = 'https://rt.cpan.org/Ticket/Display.html?id=';
my $rt_perl_base = 'https://rt.perl.org/Ticket/Display.html?id=';
my $sep          = qr{[-:]|\s*[#]?};

sub _link_issue_changelogs {
    my ( $release, @changelogs ) = @_;

    my $gh_base;
    my $rt_base;
    my $bt = $release->{resources}{bugtracker}
        && $release->{resources}{bugtracker}{web};
    my $repo = $release->{resources}{repository};
    $repo = ref $repo ? $repo->{url} : $repo;
    if ( $bt && $bt =~ m|^https?://github\.com/| ) {
        $gh_base = $bt;
        $gh_base =~ s{/*$}{/};
    }
    elsif ( $repo && $repo =~ m|\bgithub\.com/([^/]+/[^/]+)| ) {
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

    for my $changelog (@changelogs) {
        my @entries_list = $changelog->{entries};
        while ( my $entries = shift @entries_list ) {
            for my $entry (@$entries) {
                my $html = $entry->{text} =~ s/&/&amp;/gr =~ s/</&lt;/gr
                    =~ s/>/&gt;/gr =~ s/"/&quot;/gr;
                $entry->{html}
                    = _link_issue_text( $html, $gh_base, $rt_base );
                push @entries_list, $entry->{entries}
                    if $entry->{entries};
            }
        }
    }
    return @changelogs;
}

sub _link_issue_text {
    my ( $change, $gh_base, $rt_base ) = @_;
    $change =~ s{(
      (?:
        (
          \b(?:blead)?perl\s+(?:RT|bug)$sep
        |
          (?<=\[)(?:blead)?perl\s+$sep
        |
          \brt\.perl\.org\s+\#
        |
          \bP5\#
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
        (\b(?:GH|PR|[Gg]it[Hh]ub)$sep)
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

__PACKAGE__->meta->make_immutable;

1;
