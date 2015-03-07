package App::Transfer::Plugin::split_field;

# ABSTRACT: Transfer plugin for split_field

use 5.010001;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub split_field {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr    => { isa => 'Str' },
        name      => { isa => 'Str' },
        value     => { isa => 'Str' },
        limit     => { isa => 'Int' },
        separator => { isa => 'Str', default => ',' },
    );

    my ($logstr, $field, $text, $limit, $separator )
        = @p{qw(logstr name value limit separator)};
    return unless $text;
    return split /\s*$separator\s*/, $text, $limit;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::split_field - Transfer plugin for spliting text

=head1 Interface

=head2 Instance Methods

=head3 C<split_field>

Parameters:

=over

=item C<$logstr>    log string

=item C<$field>     field name

=item C<$text>      field value

=item C<$limit>     the number of destination fields

=item C<$separator> the separator char

=back

The C<split_field> method uses the C<split> function on the input
C<text> and returns an array.

=cut
