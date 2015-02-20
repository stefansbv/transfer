package App::Transfer::Plugin::null_ifzero;

# ABSTRACT: Transfer plugin: null if zero

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub null_ifzero {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return unless defined $text;
    return if $text == 0;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::null_ifzero - Transfer plugin: 'null_ifzero'

=head1 Interface

=head2 Instance Methods

=head3 C<null_ifzero>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<null_ifzero> method return undef for a value == 0 (zero).
Otherwise returns C<$text>.

=cut
