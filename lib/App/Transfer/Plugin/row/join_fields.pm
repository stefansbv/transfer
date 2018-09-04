package App::Transfer::Plugin::row::join_fields;

# ABSTRACT: Transfer plugin for join_fields

use 5.010001;
use Moose;
use namespace::autoclean;

#with 'MooX::Log::Any';

sub join_fields {
    my ( $self, $p ) = @_;
    my ( $values_aref, $separator ) = @$p{qw(values_aref separator)};
    return unless ref $values_aref;
    my @values = map { $_ } grep { defined } @{$values_aref};
    return join $separator, @values;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::join_field - Transfer plugin for joining text

=head1 Interface

=head2 Instance Methods

=head3 C<join_fields>

Parameters:

=over

=item C<$logstr>    log string

=item C<$field>     field name

=item C<$text>      field value

=item C<$separator> the separator char

=back

The C<join_fields> method uses the C<join> function on the input
C<text> and returns a string.

=cut
