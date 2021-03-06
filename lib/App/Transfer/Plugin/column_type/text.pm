package App::Transfer::Plugin::column_type::text;

# ABSTRACT: Transfer plugin for 'text' columns

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub text {
    my ($self, $p) = @_;
    my ($logstr, $field, $text ) = @$p{qw(logstr name value)};
    return unless $text;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::text - Transfer plugin for 'text' columns

=head1 Interface

=head2 Instance Methods

=head3 C<text>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<text> method return C<undef> for empty text, or C<$text>.

=cut
