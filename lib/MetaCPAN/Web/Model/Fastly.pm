package MetaCPAN::Web::Model::Fastly;

use Moose;

has ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {

    	my $key = 'magic_fetch_key_FIXME';

        my $ua = LWP::UserAgent->new(
            agent           => 'MetaCPAN PurgeBot',
            default_headers => HTTP::Headers->new(
                'X-Fastly-Key' => $key
            )
        );
    },
    lazy => 1,
);



            # $self->ua->request(    #
            #     HTTP::Request->new( PURGE => 'http://i.yhd.net/' . $key )
            # );



1;