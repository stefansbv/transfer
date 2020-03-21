package App::Transfer::Plugin::column_type::time;

# ABSTRACT: Transfer plugin for 'time' columns - stub

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub time {
    my ( $self, $p ) = @_;
    my ( $text ) = @$p{qw( value )};
    return unless defined $text;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::time - Transfer plugin for 'time' columns - stub

=head1 Interface

=head2 Instance Methods

=head3 C<time>

Parameters:

=over

=item C<$text>   field value

=back

=cut
