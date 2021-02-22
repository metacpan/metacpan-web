package MetaCPAN::Web::Model::API::Permission;

use Moose;
use Future;
use List::Util qw( uniq );

extends 'MetaCPAN::Web::Model::API';

use MetaCPAN::Web::Model::API::Release ();

=head1 NAME

MetaCPAN::Web::Model::Permission - Catalyst Model for 06perms

=cut

# copied from Model::ReleaseInfo
my %models = ( _author => 'API::Author', );
has [ keys %models ] => ( is => 'ro' );

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    $self->new( %$self,
        ( map +( $_ => $c->model( $models{$_} ) ), keys %models ),
    );
}

sub by_author {
    my ( $self, $author ) = @_;
    $self->request( [ 'permission', 'by_author', $author ] );
}

sub by_dist {
    my ( $self, $dist ) = @_;

    $self->request( [ 'package', 'modules', $dist ] )->then( sub {
        $self->by_module( @{ $_[0]->{modules} || [] } );
    } );
}

sub by_module {
    my ( $self, @modules ) = @_;

    return Future->done( {
        permissions => [],
    } )
        if !@modules;

    $self->request( '/permission/by_module', { module => \@modules } );
}

my %special = (
    NEEDHELP => 1,
    ADOPTME  => 1,
    HANDOFF  => 1
);

sub _permissions_to_notification {
    my ($self) = @_;
    sub {
        my $perm_data = shift;
        my @notif;
        for my $perms ( @{ $perm_data->{permissions} || [] } ) {
            my $type;
            my @perm_holders = ( $perms->{owner} || (),
                @{ $perms->{co_maintainers} || [] } );
            for my $maint (@perm_holders) {
                if ( exists $special{$maint} ) {
                    $type = $maint;
                    last;
                }
            }
            next
                if !$type;
            push @notif,
                {
                type        => $type,
                module_name => $perms->{module_name},
                authors     => [ grep !$special{$_}, @perm_holders ],
                };
        }

        Future->done( {
            took          => ( $perm_data->{took} || 0 ),
            notifications => \@notif,
        } );
    };
}

sub _add_email_to_notification {
    my ($self) = @_;
    sub {
        my $data = shift;

        my $notifications = $data->{notifications} || [];
        my @all_authors   = uniq( map @{ $_->{authors} }, @{$notifications} );

        $self->_author->get_multiple(@all_authors)->then( sub {
            my $author_data = shift;
            my %emails      = map +( $_->{pauseid} => $_->{email} ),
                @{ $author_data->{authors} };

            for my $notif ( @{$notifications} ) {
                my @emails = map $emails{$_}, @{ $notif->{authors} };
                @emails = map ref($_) ? @$_ : $_, @emails;
                unshift @emails, 'modules@perl.org'
                    if $notif->{type} eq 'ADOPTME' or !@emails;
                $notif->{emails} = \@emails;
            }

            Future->done( {
                took => (
                    ( $data->{took} || 0 ) + ( $author_data->{took} || 0 )
                ),
                notifications => $notifications,
            } );
        } );
    };
}

sub get_notification_info {
    my ( $self, $module ) = @_;
    $self->by_module($module)->then( $self->_permissions_to_notification )
        ->then( $self->_add_email_to_notification )->then( sub {
        my $data = shift;
        Future->done( {
            took         => $data->{took},
            notification => $data->{notifications}[0],
        } );
        } );
}

__PACKAGE__->meta->make_immutable;

1;
