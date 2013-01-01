use strict;
use warnings;
use utf8;
use Test::More;
use MetaCPAN::Web::Test;
use Encode qw( is_utf8 decode_utf8 encode_utf8 decode encode );

my ($res_body, $content_type) = ('', 'text/plain');

# hijack all requests
override_api_response sub {
    return [200, [ Content_Type => $content_type ], [$res_body] ];
};

use MetaCPAN::Web::Model::API::Module;
my $model = MetaCPAN::Web::Model::API::Module->new(api => 'http://example.com');

# $body
# $body, $type
sub get_json {
  $res_body = shift;
  $content_type = shift if @_;
  return $model->source(qw( who cares ))->recv;
}

sub get_raw {
  get_json(@_)->{raw};
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

$content_type = 'application/json';
# make sure the usual json response decodes
is_deeply get_json('{"fake": "json"}'),
    {fake => 'json'},
    'decoded json';

is_deeply get_json('{"yo": "arr! \u2620"}'),
    {yo => "arr! \x{2620}"},
    'decoded piratey json with utf-8';

# if application/json fails to decode as json it should go through the same process
# (as any other content type)
foreach my $ctype ( 'text/plain', 'application/json' ){
  $content_type = $ctype;

  foreach my $bad (
    [ encode_utf8("foo\x{FFFF_FFFF}bar"), 'encoded lax perl utf8 chars' ],
    [ "\225 cp1252 bullet", 'invalid utf-8 bytes' ],
  ){
    is get_raw($bad->[0]), $bad->[0], $bad->[1] . "come back as is";
    like pop(@warnings), qr/does not map to Unicode/, 'encode croaked';
  }

  # BLACK FLORETTE
foreach my $str (
  encode('UTF-8' => "foo\x{273f}bar"),
  join('', map { chr } 0x66, 0x6f, 0x6f,  0xe2, 0x9c, 0xbf,  0x62, 0x61, 0x72),
){
  ok !is_utf8($str), 'encoded (octets)';
  my $res = get_raw($str);
  ok  is_utf8($res), 'got back a utf8 string';
  is $res, "foo\x{273f}bar", "decoded UTF-8";
  ok !@warnings, 'no warnings after valid UTF-8' or diag shift @warnings;
}

  # HEAVY BLACK HEART
  is get_raw("i \342\235\244 metacpan"), "i \x{2764} metacpan",
    'utf-8 bytes decode to perl string';
  ok !@warnings, 'no warnings after valid UTF-8' or diag shift @warnings;

  # not sure if we'll ever actually get undef
  is get_raw(undef), '', 'undef becomes blank';
  ok !@warnings, 'no warnings for undef' or diag shift @warnings;

  # not sure if we'll ever actually get blessed object
  my $b = Blessed_String->new('holy');
  ok ref $b, 'blessed ref';
  is "$b", 'holy', 'stringifies correctly';
  is get_raw($b), 'holy', 'blessed string';
  ok !@warnings, 'no warnings for blessed obj' or diag shift @warnings;
}

done_testing;

{ package # no_index
    Blessed_String;
  sub new { bless [ $_[1] ], $_[0]; }
  use overload '""' => sub { shift->[0] };
}
