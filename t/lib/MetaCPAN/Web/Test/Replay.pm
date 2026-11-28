package MetaCPAN::Web::Test::Replay;

# ABSTRACT: Record and replay MetaCPAN API responses in tests

use strict;
use warnings;

use Cpanel::JSON::XS ();
use Digest::SHA      qw( sha256_hex );
use Encode           ();
use Future           ();
use HTTP::Response   ();
use List::Util       qw( pairs );
use MIME::Base64     qw( decode_base64 encode_base64 );
use Net::Async::HTTP ();
use Path::Tiny       qw( path );
use URI              ();

our $MODE = $ENV{METACPAN_API_MODE} || 'replay';
die "METACPAN_API_MODE must be replay, record or live, not '$MODE'\n"
    unless $MODE =~ /\A(?:replay|record|live)\z/;

# Anchored to this file so tests can run from any cwd.
our $FIXTURE_DIR
    = path(__FILE__)->absolute->parent(5)->child('fixtures/api');
our $orig_request;

if ( $MODE ne 'live' && !$orig_request ) {
    $orig_request = \&Net::Async::HTTP::do_request;
    no warnings 'redefine';
    *Net::Async::HTTP::do_request = \&do_request;
}

my $json   = Cpanel::JSON::XS->new->utf8->canonical;
my $pretty = Cpanel::JSON::XS->new->utf8->canonical->pretty;

sub _canonical_url {
    my $uri   = URI->new( shift->uri );
    my @pairs = pairs $uri->query_form;

    # Stable sort by key so repeated keys keep their original value order.
    my @order
        = sort { $pairs[$a][0] cmp $pairs[$b][0] || $a <=> $b } 0 .. $#pairs;
    my $out = URI->new( $uri->path );
    $out->query_form( map { @{ $pairs[$_] } } @order );
    return $out->as_string;
}

sub _is_json { $_[0]->content_type eq 'application/json' }

# Multipart POST bodies (Pod pod2html) have random boundaries; unsupported.
sub _canonical_body {
    my $req = shift;
    return $req->content unless _is_json($req);
    return $json->encode( $json->decode( $req->content ) );
}

# Fixtures are committed, so OAuth credentials must never be recorded or printed.
my $SECRET = qr/access_token|client_secret/;

sub _has_secret {
    my $req = shift;
    return 1 if $req->uri->path =~ m{/oauth2/};
    return 1
        if grep { $_->[0] =~ /\A(?:$SECRET)\z/ } pairs $req->uri->query_form;
    return _is_json($req) && $req->content =~ /"(?:$SECRET)"\s*:/;
}

sub _redacted_url {
    return _canonical_url(shift) =~ s/([?&](?:$SECRET)=)[^&]*/$1XXX/gr;
}

sub request_key {
    my $req = shift;
    return sha256_hex( join "\0", $req->method, _canonical_url($req),
        _canonical_body($req) );
}

sub do_request {
    my ( $self, %args ) = @_;
    my $req = $args{request};

    if ( !$req ) {
        goto &$orig_request if $MODE eq 'record';
        return Future->fail(
            'MetaCPAN::Web::Test::Replay only supports do_request( request => ... ); method/uri calls (e.g. Model::GitHub) are not replayable',
            'http'
        );
    }

    my $file = path( $FIXTURE_DIR, request_key($req) . '.json' );

    if ( $MODE eq 'record' ) {
        return Future->fail(
            'Refusing to record a request containing OAuth credentials',
            'http' )
            if _has_secret($req);

        # Transport failures propagate without writing a fixture.
        return $orig_request->( $self, %args )->then( sub {
            my $res = shift;

            # A transient server error would otherwise be replayed forever.
            if ( $res->is_server_error ) {
                warn sprintf "Not recording %s response for %s %s\n",
                    $res->code, $req->method, _canonical_url($req);
            }
            else {
                _save( $file, $req, $res );
            }
            Future->done($res);
        } );
    }

    return Future->done( _load($file) ) if -e $file;

    my $msg = sprintf
        "No recorded API response for %s %s; re-record with: METACPAN_API_MODE=record prove -lr %s\n",
        $req->method, _redacted_url($req), $0;
    warn $msg;
    return Future->fail( $msg, 'http' );
}

sub _save {
    my ( $file, $req, $res ) = @_;
    my $body = $res->decoded_content( charset => 'none' );
    my $text = eval {
        Encode::decode( 'UTF-8', $body,
            Encode::FB_CROAK | Encode::LEAVE_SRC );
    };
    my $type = $res->header('Content-Type');

    $file->parent->mkpath;

    # spew_raw writes a temp file and renames it, so prove -j is safe.
    $file->spew_raw( $pretty->encode( {
        method => $req->method,
        url    => _canonical_url($req),
        (
            _is_json($req)
            ? ( request_body =>
                    Encode::decode( 'UTF-8', _canonical_body($req) ) )
            : ()
        ),
        status  => $res->code,
        headers => { defined $type ? ( 'Content-Type' => $type ) : () },
        (
            defined $text ? ( body => $text )
            : ( body_base64 => encode_base64( $body, q{} ) )
        ),
    } ) );
    return;
}

sub _load {
    my $data = $json->decode( shift->slurp_raw );
    my $body
        = exists $data->{body_base64}
        ? decode_base64( $data->{body_base64} )
        : Encode::encode( 'UTF-8', $data->{body} );
    return HTTP::Response->new( $data->{status}, undef,
        [ %{ $data->{headers} } ], $body );
}

1;

=head1 DESCRIPTION

Wraps L<Net::Async::HTTP/do_request> so tests replay API responses stored in
F<t/fixtures/api> instead of calling the live API. See C<METACPAN_API_MODE>
in L<MetaCPAN::Web::Test>.

=cut
