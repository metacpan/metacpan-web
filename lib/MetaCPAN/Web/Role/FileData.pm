package MetaCPAN::Web::Role::FileData;
use Moose::Role;
use Future ();
use namespace::autoclean;
use Ref::Util qw( is_arrayref );

# the MIME type coming from the API is not always useful. Use our own mapping
# of extensions to override what the API gives us.
my %ext_mime_map = qw(
    pl          text/x-script.perl
    t           text/x-script.perl
    pod         text/x-pod
    pm          text/x-script.perl-module
    yaml        text/yaml
    yml         text/yaml
    js          application/javascript
    json        application/json
    c           text/x-c
    h           text/x-c
    xs          text/x-c
    md          text/markdown
    mkd         text/markdown
    mkdn        text/markdown
    mdwn        text/markdown
    mdown       text/markdown
    mdtxt       text/markdown
    mdtext      text/markdown
    markdown    text/markdown
);

my %file_mime_map = qw(
    alienfile   text/x-script.perl
    cpanfile    text/x-script.perl
    Changes     text/x-cpan-changelog
);

my ($EXT_RE) = map qr{$_}i, join '|', sort keys %ext_mime_map;

sub _groom_fileinfo {
    my ( $self, $sub, $path ) = @_;
    sub {
        my $data  = shift;
        my $files = $data;
        $files = [ $files // () ]
            if !is_arrayref $files;
        for my $sub_key (@$sub) {
            $files = [
                map {
                    my $file = $_->{$sub_key};
                    is_arrayref($file)  ? @$file
                        : defined $file ? $file
                        :                 ();
                } @$files
            ];
        }

        for my $file (@$files) {
            %$file = %{ $self->_groom_file( $file, $path ) };
        }
        return Future->done($data);
    };
}

sub _groom_file {
    my ( $self, $file, $request_path ) = @_;

    $file = {%$file};
    if ( $file->{directory} ) {
        delete $file->{mime};
        return $file;
    }
    elsif ( !$file->{path} ) {
        return $file;
    }

    my $path = $file->{path};
    my $name = $file->{name} // $path =~ s{.*/}{}r;

    if ( my $modules = $file->{module} ) {
        $file->{has_associated_pod} = 1
            if grep $_->{associated_pod}, @$modules;
        $file->{has_authorized_module} = 1
            if grep +( $_->{authorized} && $_->{indexed} ), @$modules;

        if ( $request_path && @$request_path ) {
            my ($documented_module) = grep {
                $_->{associated_pod}
                    && ( !$file->{documentation}
                    || $_->{name} eq $file->{documentation} )
                    && ( @$request_path > 1
                    || $_->{name} eq $request_path->[0] )
            } @$modules;

            if ($documented_module) {
                $file->{documented_module} = $documented_module;
                $file->{documentation}     = $documented_module->{name};

                my $assoc_pod = $documented_module->{associated_pod};

                if (   $assoc_pod
                    && $assoc_pod ne
                    "$file->{author}/$file->{release}/$file->{path}" )
                {
                    $file->{pod_path}
                        = $assoc_pod
                        =~ s{^\Q$file->{author}/$file->{release}/}{}r;
                }
            }
        }
    }

    if ( exists $file_mime_map{$name} ) {
        $file->{mime} = $file_mime_map{$name};
    }
    elsif ( $name =~ m{\.($EXT_RE)\z}o ) {
        $file->{mime} = $ext_mime_map{ lc $1 };
    }

    return $file;
}

1;
