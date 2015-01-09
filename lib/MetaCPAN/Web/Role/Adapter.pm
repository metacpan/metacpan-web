package MetaCPAN::Web::Role::Adapter;

use Moose::Role;

=head1 METHODS

=head2 extract_first_element

Elasticsearch 1.x changed the data structure returned when fields are used.
For example before one could get a ArrayRef[HashRef[Str]] where now
that will come in the form of ArrayRef[HashRef[ArrayRef[Str]]]

This function will select the first element given an array of hash of array.
So this:

    [
      {
        distribution => ['WhizzBang'],
        author       => ['EVE'],
      },
       ...
   ]

becomes:

    [
      {
        distribution => 'WhizzBang',
        author       => 'EVE',
      },
      ...
    ]

=cut

sub extract_first_element {
    my ( $self, $array ) = @_;
    foreach my $hash ( @{$array} ) {
        foreach my $field ( %{$hash} ) {
            my $value = $hash->{$field};

            # We only extract the first element when have an ArrayRef
            next if not( ref($value) and ( ref($value) eq 'ARRAY' ) );
            $hash->{$field} = $hash->{$field}->[0];
        }
    }
    return $array;
}

1;
