package MetaCPAN::CPANCover;

use strict;
use warnings;

use CHI;
use Cpanel::JSON::XS;
use MetaCPAN::Web::Types qw( HashRef Uri );
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use WWW::Mechanize::Cached;

has cache => (
    is      => 'ro',
    isa     => 'CHI::Driver::SharedMem',
    lazy    => 1,
    default => sub {
        my $cache = CHI->new(
            driver     => 'SharedMem',
            expires_in => '1d',
            size       => 256 * 1024,
            shmkey     => 42,
        );
    },
);

has current_reports => (
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    handles => {
        get_report => 'get',
    },
    lazy    => 1,
    builder => '_build_current_reports',
);

has ua => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    builder => '_build_ua',
);

has uri => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    default => 'http://cpancover.com/latest/cpancover.json',
);

sub _build_ua {
    my $self = shift;
    return WWW::Mechanize::Cached->new(
        autocheck => 0,
        cache     => $self->cache
    );
}

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
