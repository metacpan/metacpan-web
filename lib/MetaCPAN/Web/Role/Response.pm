package MetaCPAN::Web::Role::Response;

use Moose::Role;
use DateTime::Format::HTTP;
use Regexp::Common qw(time);

=head2 last_modified

Set the C<Last-Modified> header to the value passed as first parameter.
The parameter can either be a L<DateTime> object, epoch seconds or
an ISO8601 formatted date string.

=cut

sub last_modified {
    my ( $self, $date ) = @_;
    if ( $date =~ /^\d+$/ ) {
        $date = DateTime->from_epoch( epoch => $date );
    }
    elsif ( $date =~ /$RE{time}{iso}{-keep}/ ) {
        $date = eval {
            DateTime->new(
                year   => $2,
                month  => $3,
                day    => $4,
                hour   => $5,
                minute => $6,
                second => $7,
            );
        };
    }
    return unless ( eval { $date->isa('DateTime') } );
    $self->header(
        'Last-Modified' => DateTime::Format::HTTP->format_datetime($date) );
}

1;
