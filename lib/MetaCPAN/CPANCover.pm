package MetaCPAN::CPANCover;

use strict;
use warnings;

use Cpanel::JSON::XS;
use MetaCPAN::Web::Types qw( HashRef Uri );
use Moose;
use Try::Tiny;
use WWW::Mechanize::Cached;

has current_reports => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_current_reports',
);

has uri => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    default => 'http://cpancover.com/latest/cpancover.json',
);

has ua => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    default => sub {
        WWW::Mechanize::Cached->new( autocheck => 0 );
    },
);

sub _build_current_reports {
    my $self = shift;
    my $res  = $self->ua->get( $self->uri );
    return {} if !$res->is_success;

    my $reports = {};
    try {
        $reports = decode_json( $res->content );
    };

    return $reports;
}

__PACKAGE__->meta->make_immutable;
1;
