package App::Transfer::Plugin::no_space;

# ABSTRACT: Transfer plugin: no spaces

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub no_space {
    my ( $self, $p ) = @_;
    my ($logstr, $field, $text, $len ) = @$p{qw(logstr name value length)};
    return unless $text;
    $text =~ s{\s+}{}gmx;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::no_space - Transfer plugin: 'no_space'

=head1 Interface

=head2 Instance Methods

=head3 C<no_space>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=item C<$len>    field length

=back

The C<no_space> method remove all space chars (regex: \s+) and returns
the resulting string.

=cut
