package MetaCPAN::Web::Role::Elasticsearch::Adapter;

use Moose::Role;

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
    my ( $self, $array, $fields ) = @_;
    my $has_fields = defined $fields ? 1 : 0;
    $fields ||= [];
    my %fields_to_extract = map { $_ => 1 } @{$fields};
    foreach my $hash ( @{$array} ) {
        foreach my $field ( %{$hash} ) {
            next if ( $has_fields and not $fields_to_extract{$field} );
            my $value = $hash->{$field};

            # We only operate when have an ArrayRef of one value
            next
                if not( ref($value)
                and ( ref($value) eq 'ARRAY' )
                and ( scalar @{$value} == 1 ) );
            $hash->{$field} = $value->[0];
        }
    }
    return $array;
}

=head2 scalar_to_single_valued_arrayref

Given an ArrayRef[HashRef[Str]], turn all scalar values of the HashRef
into a single valued ArrayRef, i.e. a ArrayRef[HashRef[ArrayRef[Str]]]

So this:

    [
      {
        distribution => 'WhizzBang',
        provides     => ['Food', 'Bar'],
      },
       ...
   ]

becomes:

    [
      {
        distribution => ['WhizzBang'],
        provides       => ['Food, 'Bar'],
      },
      ...
    ]


=cut

sub scalar_to_single_valued_arrayref {
    my ( $self, $array ) = @_;
    foreach my $hash ( @{$array} ) {
        foreach my $field ( %{$hash} ) {
            my $value = $hash->{$field};

            # Move on if we already have a ref
            next if ref($value);
            $hash->{$field} = [$value];
        }
    }
    return $array;
}

1;
