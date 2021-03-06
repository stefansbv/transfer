package App::Transfer::Plugin::column_type::blob;

# ABSTRACT: Transfer plugin for 'blob' columns - stub

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub blob {
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

App::Transfer::Plugin::blob - Transfer plugin for 'blob' columns - stub

=head1 Interface

=head2 Instance Methods

=head3 C<blob>

Parameters:

=over

=item C<$text>   field value

=back

=cut
