package App::Transfer::Plugin::number_only;

# ABSTRACT: Transfer plugin: number only

use 5.010001;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub number_only {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr => { isa => 'Str' },
        name   => { isa => 'Str' },
        value  => { isa => 'Any' },
    );
    my ($text ) = @p{qw(value)};
    return unless $text;
    $text =~ s{[^\d.]+}{}g;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::number_only - Transfer plugin: 'number_only'

=head1 Interface

=head2 Instance Methods

=head3 C<number_only>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<number_only> method returns only the number from the text
(digits and dots).

=cut
