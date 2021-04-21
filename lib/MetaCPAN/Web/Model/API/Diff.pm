package MetaCPAN::Web::Model::API::Diff;
use Moose;
use namespace::autoclean;
use Digest::SHA ();
use Future;

extends 'MetaCPAN::Web::Model::API';

sub releases {
    my ( $self, @path ) = @_;
    return $self->request( '/diff/release/' . join( q{/}, @path ) )
        ->then( \&_clean );
}

sub files {
    my ( $self, $source, $target ) = @_;
    $source = file_info( $source // '' )->{id};
    $target = file_info( $target // '' )->{id};
    return $self->request( '/diff/file/' . $source . '/' . $target )
        ->then( \&_clean );
}

sub _clean {
    my $diff = shift;
    $diff->{$_} = file_info( $diff->{$_} ) for qw(source target);
    for my $file ( @{ $diff->{statistics} } ) {
        $file->{file} = $file->{source} =~ s{\A(?:[^/]+/){3}}{}r;
        delete $file->{source};
        delete $file->{target};
        ( $file->{diff_header} ) = $file->{diff} =~ s/\A(.*?)(^@@)/$2/ms;
    }
    return Future->done($diff);
}

sub file_info {
    my $path = shift;
    my ( $author, $release, @parts ) = split m{/}, $path;
    my $file_path = join '/', @parts;
    my $digest    = Digest::SHA::sha1_base64(
        join( "\0", grep defined, $author, $release, $file_path ) );
    $digest =~ tr/[+\/]/-_/;
    return {
        author  => $author,
        release => $release,
        ( length $file_path ? ( file => $file_path ) : () ),
        path => $path,
        id   => $digest,
    };
}

__PACKAGE__->meta->make_immutable;

1;
