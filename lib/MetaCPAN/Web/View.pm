package MetaCPAN::Web::View;
use strict;
use warnings;
use base 'Template::Alloy';
use mro;
use DateTime::Tiny;
use Digest::MD5 qw(md5_hex);
use Encoding;

Template::Alloy->define_vmethod( 'text',
                            dt => sub { my $date = shift;
                                $date =~ s/\..*?$//;
                                return unless($date);
                                DateTime::Tiny->from_string($date); }, );

Template::Alloy->define_vmethod( 'text',
                               to_color => sub { my $md5 = md5_hex(md5_hex(shift)); my $color = substr($md5, 0, 6);
                                   return "#$color"; }, );

sub new {
    my $class = shift;
    return $class->next::method(
        @_,
        INCLUDE_PATH => ['templates'],
        TAG_STYLE    => 'asp',

        #STRICT => 1,
        COMPILE_DIR => 'var/tmp/templates',
        COMPILE_PERL => 1,
        STAT_TTL     => 1,
        WRAPPER     => [qw(wrapper.html)],
        ENCODING    => 'utf8',
        AUTO_FILTER => 'html',
        PRE_PROCESS => ['preprocess.html'], );
}

1;
