package App::Transfer::Plugin::lookup_in_dbtable;

# ABSTRACT: Transfer plugin: lookup in a database table

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub lookup_in_dbtable {
    my ( $self, $p ) = @_;

    my ( $logstr, $fields, $table, $engine, $where, $lookup )
        = @$p{qw(logstr fields table engine where lookup)};
    return unless $lookup;

    my $result_aref = $engine->lookup( $table, $fields, $where );
    my $ret_no = scalar @{$result_aref};
    if ( $ret_no == 1 ) {
        return $result_aref->[0];
    }
    elsif ( $ret_no > 1 ) {
        my $results = '';
        foreach my $ary ( @{$result_aref} ) {
            $results .= ' ';
            $results .= "'" . join( ',', @{$ary} ) . "'";
        }
        $self->log->info(
            "$logstr lookup: multiple values for '",
            join( ',', @{$fields} ), "'='$lookup': $results" );
    }
    else {
        $self->log->info(
            "$logstr lookup: failed for '", join( ',', @{$fields} ),
            "'='$lookup'");
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::lookup_in_dbtable - Transfer plugin to lookup in tables

=head1 Interface

=head2 Instance Methods

=head3 C<lookup_in_dbtable>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  destination field name

=item C<$table>  table name

=item C<$engine> the destination engine object

=item C<$where>  where

=item C<$lookup> the value to lookup

=back

XXX

Recipe configuration example step:

  <step>
    type              = lookupdb
    datasource        = v_siruta
    field_src         = localitate
    method            = lookup_in_dbtable
    field_dst         = siruta
    field_dst         = codp
  </step>

Lookup for the C<$lookup> value in the C<$field> field where C<$where>
and return the result if ...

=cut
