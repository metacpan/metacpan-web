package MetaCPAN::Web::Controller::Release;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, $author, $release ) = split( /\//, $req->uri->path );

    my $out;

    my $cond = $self->model( '/release/_search',
                             {  query  => { match_all => {} },
                                filter => {
                                     and => [
                                         { term => { 'name.raw' => $release } },
                                         { term => { author     => $author } } ]
                                } }
      )->(
        sub {
            $out = shift->recv->{hits}->{hits}->[0]->{_source};
            my $modules = $self->get_modules( $author, $release );
            my $others =
              $self->get_others( $author, $release, $out->{distribution} );
            my $author = $self->get_author($author);
            return ( $modules & $others & $author );
        } );

    $cond->(
        sub {
            my ( $modules, $others, $author ) = shift->recv;
            $cv->send(
                     { release => $out,
                       author  => $author,
                       others =>
                         [ map { $_->{fields} } @{ $others->{hits}->{hits} } ],
                       modules =>
                         [ map { $_->{fields} } @{ $modules->{hits}->{hits} } ]
                     } );
        } );

    return $cv;
}

sub get_modules {
    my ( $self, $author, $release ) = @_;
    $self->model( '/file/_search',
                  {  query  => { match_all => {} },
                     filter => {
                               and => [
                                   { term => { release => $release } },
                                   { term => { author  => $author } },
                                   { exists => { field => 'file.module.name' } }
                               ]
                     },
                     sort   => ['documentation.raw'],
                     fields => [qw(documentation abstract module.name.raw path status)],
                  } );
}

sub get_others {
    my ( $self, $author, $release, $dist ) = @_;
    $self->model(
        '/release/_search',
        {  query  => { match_all => {} },
           filter => {
               and => [
                   { term => { 'release.distribution.raw' => $dist } },

                   # { not => {
                   #     term => { 'release.name.raw' => $release }
                   # } }
               ],

           },
           sort   => [ { date => 'desc' } ],
           fields => [qw(name date author)],
        } );
}

1;
