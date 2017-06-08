package App::Transfer::Plugin::column::one_space;

# ABSTRACT: Transfer plugin: no spaces

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub one_space {
    my ($self, $p) = @_;
    my ($logstr, $text, $len ) = @$p{qw(logstr value length)};
    return unless $text;
    $text =~ s{\s+}{ }gmx;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::one_space - Transfer plugin: 'one_space'

=head1 Interface

=head2 Instance Methods

=head3 C<one_space>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<one_space> method replaces all space chars (regex: \s+) with a
single space and returns the resulting string.

=cut
