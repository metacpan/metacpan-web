package MetaCPAN::Web::Role::Date;
use strict;
use warnings;
use Role::Tiny;

requires 'strftime';

sub to_http {
    $_[0]->strftime('%d %b %Y %T %Z');
}

sub to_ymd {
    $_[0]->strftime('%F');
}

1;
