package App::Transfer::Plugin::row::split_field;

# ABSTRACT: Transfer plugin for split_field

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub split_field {
    my ( $self, $p ) = @_;
    my ($logstr, $field, $value, $limit, $sep)
        = @$p{qw(logstr field value limit separator)};
    return unless $value;
    my $regex = qr/\s*${sep}\s*/;
    my @values = split $regex, $value, $limit;
    return wantarray ? @values : \@values;
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

=item C<$logstr>    log string

=item C<$field>     field name

=item C<$text>      field value

=item C<$limit>     the number of destination fields

=item C<$separator> the separator char

=back

The C<split_field> method uses the C<split> function on the input
C<text> and returns an array.

=cut
