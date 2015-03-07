package App::Transfer::Plugin::digits_only;

# ABSTRACT: Transfer plugin: digits only

use 5.010001;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub digits_only {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr => { isa => 'Str' },
        name   => { isa => 'Str' },
        value  => { isa => 'Any' },
    );
    my ($logstr, $field, $text ) = @p{qw(logstr name value)};
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

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<digits_only> method returns only the digits from the text.

=cut
