package App::Transfer::Plugin::split_field;

# ABSTRACT: # ABSTRACT: Transfer plugin for split_field

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub split_field {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value, $limit, $separator )
        = @$p{qw(logfld logidx name value limit separator)};
    return unless $value;
    return split /$separator/, $value, $limit;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::split_field - Transfer plugin for spliting text

=head1 Interface

=head2 Instance Methods

=head3 C<split_field>

Parameters:

=over

=item C<$logfld>    log field name

=item C<$logidx>    log field value

=item C<$field>     field name

=item C<$text>      field value

=item C<$limit>     the number of destination fields

=item C<$separator> the separator char

=back

The C<split_field> method uses the C<split> function on the input
C<text> and returns an array.

=cut
