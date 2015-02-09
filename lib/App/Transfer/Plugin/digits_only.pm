package App::Transfer::Plugin::digits_only;

# ABSTRACT: Transfer plugin: digits only

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub digits_only {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return unless $text;
    $text =~ s{[^\d]+}{}g;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::digits_only - Transfer plugin: 'digits_only'

=head1 Interface

=head2 Instance Methods

=head3 C<digits_only>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<digits_only> method returns only the digits from the text.

=cut
