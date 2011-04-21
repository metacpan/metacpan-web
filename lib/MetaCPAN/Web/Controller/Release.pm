package MetaCPAN::Web::Controller::Release;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, $author, $release ) = split( /\//, $req->uri->path );
    my ( $out, $cond );
    if ( $author && $release ) {
        $cond = $self->get_release( $author, $release );
    } else {
        $cond = $self->find_release($author);
    }

    $cond = $cond->(
        sub {
            my ($data) = shift->recv;
            $out = $data->{hits}->{hits}->[0]->{_source};
            ( $author, $release ) = ( $out->{author}, $out->{name} );
            my $modules = $self->get_modules( $author, $release );
            my $root   = $self->get_root_files( $author, $release );
            my $others = $self->get_others( $out->{distribution} );
            my $author = $self->get_author($author);
            return ( $modules & $others & $author & $root );
        } );

    $cond->(
        sub {
            my ( $modules, $others, $author, $root ) = shift->recv;
            $cv->send(
                 { release => $out,
                   author  => $author,
                   root => [ map { $_->{fields} } @{ $root->{hits}->{hits} } ],
                   others =>
                     [ map { $_->{fields} } @{ $others->{hits}->{hits} } ],
                   modules =>
                     [ map { $_->{fields} } @{ $modules->{hits}->{hits} } ] } );
        } );

    return $cv;
}

sub get_modules {
    my ( $self, $author, $release ) = @_;
    $self->model('/file/_search',
                 { query  => { match_all => {} },
                   filter => {
                               and => [
                                   { term => { release => $release } },
                                   { term => { author  => $author } },
                                   { exists => { field => 'file.module.name' } }
                               ]
                   },
                   sort => ['documentation.raw'],
                   fields =>
                     [qw(documentation abstract cpan.file.module path status)],
                 } );
}

sub find_release {
    my ( $self, $distribution ) = @_;
    $self->model(
         '/release/_search',
         { query  => { match_all => {} },
           filter => {
                and => [
                    { term => { 'release.distribution.raw' => $distribution } },
                    { term => { status                     => 'latest' } } ] }
         },
         sort => [ { date => 'desc' } ],
         size => 1 );
}

sub get_root_files {
    my ( $self, $author, $release ) = @_;
    $self->model( '/file/_search',
                  {  query  => { match_all => {} },
                     filter => {
                                 and => [ 
                                        { term => { release => $release } },
                                        { term => { author  => $author } },
                                        { term => { level     => 0 } },
                                          { term => { directory => \0 } } ]
                     },
                     fields => [qw(name)],
                     size   => 100,
                  } );
}

sub get_others {
    my ( $self, $dist ) = @_;
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
           fields => [qw(name date author version)],
        } );
}

1;
