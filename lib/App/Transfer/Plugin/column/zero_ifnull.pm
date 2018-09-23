package App::Transfer::Plugin::column::zero_ifnull;

# ABSTRACT: Transfer plugin: zero if not defined

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub zero_ifnull {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text ) = @$p{qw(logstr name value)};
    $self->log->info("$logstr '$field' empty text")
        if defined $text and $text eq q{};
    return 0 if not defined $text or $text eq q{};
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

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<zero_ifnull> method return 0 (zero) for a not defined value.
Otherwise returns C<$text>.

=cut
