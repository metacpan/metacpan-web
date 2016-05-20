package MetaCPAN::Web::Elasticsearch::Adapter;

use Ref::Util qw( is_arrayref );

our @EXPORT_OK = qw( single_valued_arrayref_to_scalar );

=head1 METHODS

=head2 single_valued_arrayref_to_scalar

Elasticsearch 1.x changed the data structure returned when fields are used.
For example before one could get a ArrayRef[HashRef[Str]] where now
that will come in the form of ArrayRef[HashRef[ArrayRef[Str]]]

This function reverses that behavior
By default it will do that for all fields that are a single valued array,
but one may pass in a list of fields to restrict this behavior only to the
fields given.

So this:

    $self->single_valued_arrayref_to_scalar(
    [
      {
        name     => ['WhizzBang'],
        provides => ['Food', 'Bar'],
      },
       ...
   ]);

yields:

    [
      {
        name     => 'WhizzBang',
        provides => ['Food', 'Bar'],
      },
      ...
    ]

and this estrictive example):

    $self->single_valued_arrayref_to_scalar(
    [
      {
        name     => ['WhizzBang'],
        provides => ['Food'],
      },
       ...
   ], ['name']);

yields:

    [
      {
        name     => 'WhizzBang',
        provides => ['Food'],
      },
      ...
    ]

=cut

sub single_valued_arrayref_to_scalar {
    my ( $array, $fields ) = @_;
    my $is_arrayref = is_arrayref($array);

    $array = [$array] unless $is_arrayref;

    my $has_fields = defined $fields ? 1 : 0;
    $fields ||= [];
    my %fields_to_extract = map { $_ => 1 } @{$fields};
    foreach my $hash ( @{$array} ) {
        foreach my $field ( %{$hash} ) {
            next if ( $has_fields and not $fields_to_extract{$field} );
            my $value = $hash->{$field};

            # We only operate when have an ArrayRef of one value
            next unless is_arrayref($value) && scalar @{$value} == 1;
            $hash->{$field} = $value->[0];
        }
    }
    return $is_arrayref ? $array : @{$array};
}

1;
