package MetaCPAN::Web::Role::FileData;
use Moose::Role;
use Future    ();
use Ref::Util qw(is_arrayref);
use namespace::autoclean;

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
    my ( $self, @sub ) = @_;
    sub {
        my $data  = shift;
        my $files = $data;
        $files = [ $files // () ]
            if !is_arrayref $files;
        for my $sub (@sub) {
            $files = [
                map {
                    my $file = $_->{$sub};
                    is_arrayref($file)  ? @$file
                        : defined $file ? $file
                        :                 ();
                } @$files
            ];
        }

        for my $file (@$files) {
            %$file = %{ $self->_groom_file($file) };
        }
        return Future->done($data);
    };
}

sub _groom_file {
    my ( $self, $file ) = @_;

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
