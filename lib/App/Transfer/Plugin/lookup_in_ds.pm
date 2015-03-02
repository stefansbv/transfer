package App::Transfer::Plugin::lookup_in_ds;

# ABSTRACT: Transfer plugin: lookup in data source

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub lookup_in_ds {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $lookup_table )
        = @$p{qw(logstr field_src value lookup_table)};
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

App::Transfer::Plugin::lookup_in_ds - Transfer plugin to lookup in datasource

=head1 Interface

=head2 Instance Methods

=head3 C<lookup_in_ds>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  destination field name

=item C<$table>  datasource table name

=item C<$text>   the value to lookup

=back

XXX

Recipe configuration example step:

  <step>
...
  </step>

Lookup for the C<$lookup> value in the C<$field> field where C<$where>
and return the result if ...

=cut
