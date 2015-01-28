package App::Transfer::Plugin::copy_nonzero;

# ABSTRACT: move filtered

use 5.010001;
use Moose;
use List::Util qw/any none/;
use List::MoreUtils qw/each_array/;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub copy_nonzero {
    my ( $self, $p ) = @_;
    my ($logfld, $logidx, $field, $value, $fields_src, $attributes)
        = @$p{qw(logfld logidx name value fields_src attributes)};
    if ( none { $_ != 0 } @{$value} ) {
        my $msg = $attributes->{MOVE} ? 'move' : 'copy';
        $self->log->info("[$logfld=$logidx] $msg to '$field' skipped: all values == 0");
        return;
    }
    else {
        my $ea = each_array( @{$fields_src}, @{$value} );
        my $r  = {};
        while ( my ( $field_src, $val ) = $ea->() ) {
            $val //= 0;
            if ( $val != 0 ) {
                $r->{$field} = $val;
                if ( $field_src eq 'casa_inc' or $field_src eq 'banca_inc' ) {
                    $r->{tip_op}  = 'I';
                    $r->{tip_doc} = 1;
                    $r->{cont_c}  = '411';
                    $r->{tva}     = 0;
                }
                elsif ( $field_src eq 'casa_pl' or $field_src eq 'banca_pl' )
                {
                    $r->{tip_op}  = 'P';
                    $r->{tip_doc} = 2;
                    $r->{cont_c}  = '401';
                    $r->{tva}     = 1;
                }
            }
            $r->{$field_src} = undef if $attributes->{MOVE};
            $r->{id_user} = 'stefan';
        }
        return $r;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

=head2 copy_nonzero

Move content of the source field to the destination field if the value
is not in the lookup list.

Example recipe configuration:

    <step>
      type              = copy
      field_src         = casa_inc
      field_src         = casa_pl
      field_src         = banca_inc
      field_src         = banca_pl
      method            = copy_nonzero
      field_dst         = suma
    </step>

=cut

1;
