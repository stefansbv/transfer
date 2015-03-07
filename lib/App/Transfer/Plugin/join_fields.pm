package App::Transfer::Plugin::join_fields;

# ABSTRACT: Transfer plugin for join_fields

use 5.010001;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub join_fields {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr    => { isa => 'Str' },
        name      => { isa => 'Str' },
        value     => { isa => 'ArrayRef' },
        separator => { isa => 'Str', default => ' ' },
    );
    my ( $logstr, $text, $separator ) = @p{qw(logstr value separator)};
    return unless ref $text;
    my $new_text = join $separator, @{$text};
    return $new_text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::join_field - Transfer plugin for joining text

=head1 Interface

=head2 Instance Methods

=head3 C<join_fields>

Parameters:

=over

=item C<$logstr>    log string

=item C<$field>     field name

=item C<$text>      field value

=item C<$separator> the separator char

=back

The C<join_fields> method uses the C<join> function on the input
C<text> and returns a string.

=cut
