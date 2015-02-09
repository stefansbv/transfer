package App::Transfer::Plugin::first_upper;

# ABSTRACT: Transfer plugin: first upper

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub first_upper {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return unless $text;
    return uc substr $text, 0, 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::first_upper - Transfer plugin: 'first_upper'

=head1 Interface

=head2 Instance Methods

=head3 C<first_upper>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<first_upper> method returns one character, an uppercased version
of the first character of the string.

=cut
