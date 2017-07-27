package App::Transfer::Plugin::lookup_in_dbtable;

# ABSTRACT: Transfer plugin: lookup in a database table

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub lookup_in_dbtable {
    my ( $self, $p ) = @_;
    my ( $logstr, $fields, $table, $engine, $where, $lookup, $attribs)
        = @$p{qw(logstr fields table engine where lookup attributes)};
    return unless $lookup;

    my $result_aref = $engine->lookup( $table, $fields, $where, $attribs );
    my $ret_no = scalar @{$result_aref};
    if ( $ret_no == 1 ) {
        return $result_aref->[0];
    }
    elsif ( $ret_no > 1 ) {
        my $results = '';
        foreach my $h ( @{$result_aref} ) {
            $results .= ' ';
            $results .= "'" . join( ',', values %{$h} ) . "'";
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

App::Transfer::Plugin::lookup_in_dbtable - lookup in tables

=head1 Interface

=head2 Instance Methods

=head3 C<lookup_in_dbtable>

Parameters:

=over

=item C<$logstr> log string

Used for identifying the source row data.  It is a string like: "[recno=143"

=item C<$field>  a field array reference to be passed to C<$engine->lookup>

=item C<$table>  the database dictionary table name to be passed to C<$engine->lookup>

=item C<$where>  a hash reference to be passed to C<$engine->lookup>

=item C<$engine> the destination engine object

=item C<$lookup> the value to lookup

Returns a hash reference.

   {
     field_name1 => value1,
     field_name2 => value2,
     ...
   }

or nothing if there are no results or more then one result and in this
case also creates a log entry.

=back

=cut
