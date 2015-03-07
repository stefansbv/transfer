package App::Transfer::Plugin::lookup_in_ds;

# ABSTRACT: Transfer plugin: lookup in data source

use 5.010001;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub lookup_in_ds {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr       => { isa => 'Str' },
        field_src    => { isa => 'Str' },
        value        => { isa => 'Str' },
        lookup_table => { isa => 'ArrayRef' },
    );

    my ( $logstr, $field, $text, $lookup_table )
        = @p{qw(logstr field_src value lookup_table)};
    return unless $text;
    foreach my $rec ( @{$lookup_table} ) {
        foreach my $key ( keys %{$rec} ) {
            return $rec->{$key} if $text =~ m{$key};
        }
    }
    $self->log->info("$logstr lookup: failed for '$field'='$text'");
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::lookup_in_ds - lookup in datasources

=head1 Interface

=head2 Instance Methods

=head3 C<lookup_in_ds>

Parameters:

=over

=item C<$logstr> log string

Used for identifying the source row data.  It is a string like: "[recno=143"

=item C<$lookup_table> a AoH dictionary table

=item C<$text>         the value to lookup

=item C<$field>        the source field, used for logging

=back

=cut
