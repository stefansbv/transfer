package App::Transfer::Plugin::column::null_ifundef;

# ABSTRACT: Transfer plugin: null if undef string

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub null_ifundef {
    my ($self, $p) = @_;
    my ($logstr, $text ) = @$p{qw(logstr value)};
    return unless defined $text;
    return if $text eq 'undef';
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::null_ifundef - Transfer plugin: 'null_ifundef'

=head1 Interface

=head2 Instance Methods

=head3 C<null_ifundef>

Parameters:

=over

=item C<$logstr> log string

=item C<$text>   field value

=back

The C<null_ifundef> method return undef for a value == 0 (zero).
Otherwise returns C<$text>.

=cut
