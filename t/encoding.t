# don't magically change things for these tests
no utf8;

use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;
use Encode qw( is_utf8 decode_utf8 encode_utf8 decode encode );

my ($res_body, $content_type) = ('', 'text/plain');

# hijack all requests
api_response sub {
    return ($res_body, {'content-type' => $content_type});
};

use MetaCPAN::Web::Model::API::Module;
my $model = MetaCPAN::Web::Model::API::Module->new(api => 'http://example.com');

# $body
# $body, $type
sub get_raw {
  $res_body = shift.'';
  $content_type = shift if @_;
  my $res = $model->source(qw( who cares ))->recv->{raw};
  return $res;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

chomp(my $filedata = <DATA>);

# make sure the usual json response decodes
($res_body, $content_type) = ('{"fake": "json"}', 'application/json');
is_deeply $model->source(qw( who cares ))->recv(), {fake => 'json'}, 'decoded json';

# is this actually testing anything (useful)?

# if application/json fails to decode as json it should go through the same process
foreach my $ctype ( 'text/plain', 'application/json' ){
  $content_type = $ctype;

  # invalid Unicode, but ok for perl's internal encoding
  is  get_raw(encode_utf8("foo\x{FFFF_FFFF}bar")), encode_utf8("foo\x{FFFF_FFFF}bar"), "encoded lax utf8 character comes back as is";
  like pop(@warnings), qr/does not map to Unicode/, 'encode croaked';
  is  get_raw("foo\x{FFFF_FFFF}bar"), "foo\x{FFFF_FFFF}bar", "unencoded lax utf8 character comes back as is";
  like pop(@warnings), qr/cannot decode string with wide characters/i, "got wide char warning, don't care";

  # BLACK FLORETTE
  my $str = encode_utf8("foo\x{273f}bar");
  ok !is_utf8($str), 'encoded';
  my $res = get_raw($str);
  ok  is_utf8($res), 'got back a utf8 string';
  is $res, "foo\x{273f}bar", "decoded UTF-8";
  ok !@warnings, 'no warnings after valid UTF-8' or diag shift @warnings;

  # HEAVY BLACK HEART
  is get_raw($filedata), "i \x{2764} metacpan", 'correct message';
  ok !@warnings, 'no warnings after valid UTF-8' or diag shift @warnings;
}

done_testing;

__DATA__
i ❤ metacpan
