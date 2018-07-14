package App::Transfer::Plugin::column::trim;

# ABSTRACT: Transfer plugin [column]: trim

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub trim {
    my ($self, $p) = @_;
    my ($logstr, $text, $len ) = @$p{qw(logstr value length)};
    return unless $text;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::trim - Transfer plugin: 'trim'

=head1 Interface

=head2 Instance Methods

=head3 C<trim>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<trim> method removes all space chars from the left and right
side of the text and returns the resulting string.

=cut
