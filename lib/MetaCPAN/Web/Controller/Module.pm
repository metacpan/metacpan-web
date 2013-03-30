package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;
use HTML::Restrict;

BEGIN { extends 'MetaCPAN::Web::Controller' }

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

sub path : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, @path ) = @_;

    # force consistent casing in URLs
    if ( @path > 2 && $path[0] ne uc($path[0]) ) {
        $c->res->redirect( '/module/' . join( '/', uc(shift @path), @path ), 301 );
        $c->detach();
    }

    my $model = $c->model('API::Module');
    my $data = @path > 2 ? $model->get(@path)->recv : $model->find(@path)->recv;

    if($data->{directory}) {
        $c->res->redirect( '/source/' . join( '/', @path ), 301 );
        $c->detach;
    }

    ( $data->{documentation}, my $pod )
        = map { $_->{name}, $_->{associated_pod} }
        grep { @path > 1 || $path[0] eq $_->{name} }
        grep { !$data->{documentation} || $data->{documentation} eq $_->{name} }
        grep { $_->{associated_pod} } @{ $data->{module} || [] };

    $c->detach('/not_found') unless ( $data->{name} );
    my $reqs = $self->api_requests(
        $c,
        {   pod => $c->model('API')
                ->request( '/pod/' . ( $pod || join( '/', @path ) ) . '?show_errors=1' ),
            release => $c->model('API::Release')
                ->get( @{$data}{qw(author release)} ),
            recommendations_instead_of => $c->model('API::Recommendation')
                ->get( undef, map { $_->{name} } @{$data->{module}} ),
            recommendations_supplanted_by => $c->model('API::Recommendation')
                ->get_supplanted( undef, map { $_->{name} } @{$data->{module}} ),
        },
        $data,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results( $c, $reqs, $data );
    $self->add_favorites_data( $data, $reqs->{favorites}, $data );

    $data->{recommendation} = {
        instead_of    => $reqs->{recommendations_instead_of}{instead_of},
        supplanted_by => $reqs->{recommendations_supplanted_by}{supplanted_by},
    };

    my $hr = HTML::Restrict->new;
    $hr->set_rules(
        {   a       => [qw( href target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [],
            dd      => ['id'],
            div     => [qw(id style)],
            dl      => ['id'],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            img     => [qw( alt border height width src style / )],
            li      => ['id'],
            ol      => [],
            p       => [qw(class style)],
            pre     => [qw(id class style)],
            span    => [qw(style)],
            strong  => [],
            sub     => [],
            sup     => [],
            table => [qw( style class border cellspacing cellpadding align )],
            tbody => [],
            td    => [qw(style class)],
            tr    => [qw(style class)],
            u     => [],
            ul    => ['id'],
        }
    );

    # ensure page is not cached when latest release is a trial
    $c->res->last_modified(
               $reqs->{versions}->{hits}->{hits}->[0]->{fields}->{date}
            || $data->{date} );

    $c->stash(
        {   module   => $data,
            pod      => $hr->process( $reqs->{pod}->{raw} ),
            release  => $reqs->{release}->{hits}->{hits}->[0]->{_source},
            recommendations => $self->groom_recommendations( $c, $data ),
            template => 'module.html',
        }
    );
}

=pod 

For giggles and to get the ball running, I'm assuming that recommendations are per-modules.

I'm also assuming that we have the modules recommended over this one, and
those under it. And that the whole this has the format:

    $data->{recommendations} = {
        recommended_over => {
            'Foo'       => [ 'AUTHOR1', 'AUTHOR2' ],
            'Bar::Baz'  => [ 'AUTHOR3' ],
        },
        rather_use => {
            'Frob::Uscate' => [ 'AUTHOR4' ],
        },
    };

Yes, 'rather_use' is a crappy key, but for now it'll do. We'll s/// it to
something decent down the line.

=cut

sub groom_recommendations {
    my( $self, $c, $data ) = @_;

    # sample data
    $data->{recommendations} = {
        recommended_over => {
            'Foo'       => [ 'AUTHOR1', 'AUTHOR2' ],
            'Bar::Baz'  => [ 'AUTHOR3' ],
            'Frob::Uscate' => [ 'AUTHOR5', 'AUTHOR6' ],
        },
        rather_use => {
            'Frob::Uscate' => [ 'AUTHOR4' ],
        },
    };

    my $r = $data->{recommendations} or return [];

    my %rec;

    if ( my $plus = $r->{recommended_over} ) {
        while( my ($module,$votes) = each %$plus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{sum} = $rec{$module}{plus} = scalar @$votes;
        }
    }

    if ( my $minus = $r->{rather_use} ) {
        while( my ($module,$votes) = each %$minus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{minus} = scalar @$votes;
            $rec{$module}{sum}  += scalar @$votes;
        }
    }

    return [
        reverse sort { $a->{sum} <=> $b->{sum} } values %rec
    ];

}

1;
