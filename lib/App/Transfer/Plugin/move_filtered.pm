package App::Transfer::Plugin::move_filtered;

# ABSTRACT: move filtered

use 5.010001;
use Moose;
use List::Util qw/any/;
use namespace::autoclean;

with 'MooX::Log::Any';

=head2 move_filtered

Move content of the source field to the destination field if the value
is not in the lookup list.

Example recipe configuration:

    <datasource contr_type>
      <record>
        item            = rent
        code            = R
      </record>
      <record>
        item            = loan
        code            = L
      </record>
    </datasource>

    <step>
      type              = copy
      datasource        = contr_type
      field_src         = contr_type
      method            = move_filtered
      field_dst         = obs
      attributes        = MOVE
    </step>

=cut

sub move_filtered {
    my ( $self, $p ) = @_;
    my ($logfld, $logidx, $field, $text, $lookup_list, $field_src, $field_dst, $attributes)
        = @$p{qw(logfld logidx name value lookup_list field_src field_dst attributes)};
    return unless $text;
    unless ( any { $text eq $_ } @{$lookup_list} ) {
        my $r   = {};
        my $msg = $attributes->{MOVE} ? 'move' : 'copy';
        $self->log->info("[$logfld=$logidx] $msg: '$field_src'='$text' to $field_dst");
        $r->{$field_src} = undef if $attributes->{MOVE};
        $r->{$field_dst} = $text;
        return $r;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
