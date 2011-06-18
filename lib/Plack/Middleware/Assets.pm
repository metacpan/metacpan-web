package Plack::Middleware::Assets;

# ABSTRACT: Concatenate and minify JavaScript and CSS files
use strict;
use warnings;

use parent qw(Plack::Middleware);
__PACKAGE__->mk_accessors(qw(content minify files key mtime type));

use Digest::MD5 'md5_hex';
use JavaScript::Minifier::XS ();
use CSS::Minifier::XS        ();
use HTTP::Date               ();

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    local $/;
    $self->content(
        join(
            "\n",
            map {
                open my $fh, '<', $_ or die "$_: $!";
                "/* $_ */\n" . <$fh>
              } @{ $self->files }
        )
    );
    $self->type( (grep { /\.css$/ } @{ $self->files }) ? 'css' : 'js' )
      unless ( $self->type );
    $self->minify(1) unless(defined $self->minify);
    $self->content($self->_minify) if $self->minify;

    $self->key( md5_hex( $self->content ) );
    my @mtime = map { ( stat($_) )[9] } @{ $self->files };
    $self->mtime( ( reverse( sort(@mtime) ) )[0] );

      return $self;
}

sub _minify {
    my $self = shift;
    no strict 'refs';
    my $method =
      $self->type eq 'css'
      ? 'CSS::Minifier::XS::minify'
      : 'JavaScript::Minifier::XS::minify';
    return $method->( $self->content );
}

sub serve {
    my $self         = shift;
    my $content_type = return [
        200,
        [
              'Content-Type' => $self->type eq 'css'
            ? 'text/css'
            : 'text/javascript',
            'Content-Length' => length( $self->content ),
            'Last-Modified'  => HTTP::Date::time2str( $self->mtime ),
        ],
        [ $self->content ]
    ];
}

sub call {
    my $self = shift;
    my $env  = shift;
    $env->{'psgix.assets'} ||= [];
    my $url = '/_asset/' . $self->key;
    unshift( @{ $env->{'psgix.assets'} }, $url );
    return $self->serve if $env->{PATH_INFO} eq $url;

    return $self->app->($env);
}

1;

__END__

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "Assets",
          files => [<static/js/*.js>];
      enable "Assets",
          files => [<static/css/*.css>],
          minify => 0;
      $app;
  };

  # $env->{'psgix.assets'}->[0] points at the first asset.

=head1 DESCRIPTION

Plack::Middleware::Assets concatenates JavaScript and CSS files
and minifies them. A C<md5> digest is generated and used as
unique url to the asset. The C<Last-Modified> header is set to
the C<mtime> of the most recently changed file.
The concatented content is held in memory.

=head1 CONFIGURATIONS

=over 4

=item files

Files to concatenate.

=item minify

Boolean to indicate whether to compress or not. Defaults to C<1>.

=item type

Type of the asset. Either C<css> or C<js>. This is derived automatically
from the file extensions but can be set explicitly if you are using
non-standard file extensions.

=back

=head1 SEE ALSO

L<Catalyst::Plugin::Assets>

Inspired by L<Plack::Middleware::JSConcat>
