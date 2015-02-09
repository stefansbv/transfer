package App::Transfer::Plugin::zero_ifnull;

# ABSTRACT: Transfer plugin: zero if not defined

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub zero_ifnull {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return 0 if not defined $text;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::zero_ifnull - Transfer plugin: 'zero_ifnull'

=head1 Interface

=head2 Instance Methods

=head3 C<zero_ifnull>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<zero_ifnull> method return 0 (zero) for a not defined value.
Otherwise returns C<$text>.

=cut
