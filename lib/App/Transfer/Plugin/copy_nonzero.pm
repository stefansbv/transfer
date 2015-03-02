package App::Transfer::Plugin::copy_nonzero;

# ABSTRACT: move filtered

use 5.010001;
use Moose;
use List::Util qw/any none/;
use List::MoreUtils qw/each_array/;
use namespace::autoclean;

with 'MooX::Log::Any';

sub copy_nonzero {
    my ( $self, $p ) = @_;
    my ($logstr, $field, $values, $fields_src, $attributes)
        = @$p{qw(logstr field_dst value field_src attributes)};
    if ( none { $_ != 0 } @{$values} ) {
        my $op = $attributes->{MOVE} ? 'move' : 'copy';
        $self->log->warn("$logstr $op to '$field' skipped: all values == 0");
        return;
    }
    else {
        my $ea = each_array( @{$fields_src}, @{$values} );
        my $r  = {};
        while ( my ( $field_src, $val ) = $ea->() ) {
            $val //= 0;
            $r->{$field} = ( $field_src eq 'debit' ? $val : -$val )
                if $val != 0;
            $r->{$field_src} = undef if $attributes->{MOVE};
        }
        return $r;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

=head2 copy_nonzero

Move content of the source field to the destination field if the value
is not zero.

The required recipe configuration:

    <step>
      type              = copy
      field_src         = debit
      field_src         = credit
      method            = copy_nonzero
      field_dst         = suma
    </step>

=cut

1;
