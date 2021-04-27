package MetaCPAN::Web::Role::Response;

use Moose::Role;
use DateTime::Format::HTTP;
use DateTime::Format::ISO8601 ();

=head2 last_modified

Set the C<Last-Modified> header to the value passed as first parameter.
The parameter can either be a L<DateTime> object, epoch seconds or
an ISO8601 formatted date string.

=cut

sub last_modified {
    my ( $self, $date ) = @_;
    if ( ref $date ) {

        # assume it's a DateTime
    }
    elsif ( $date =~ /^\d+$/ ) {
        $date = DateTime->from_epoch( epoch => $date );
    }
    else {
        $date = DateTime::Format::ISO8601->parse_datetime($date);
    }
    return unless ( eval { $date->isa('DateTime') } );
    $self->header(
        'Last-Modified' => DateTime::Format::HTTP->format_datetime($date) );
}

1;
