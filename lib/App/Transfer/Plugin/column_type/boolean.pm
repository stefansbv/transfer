package App::Transfer::Plugin::column_type::boolean;

# ABSTRACT: Transfer plugin for 'boolean' columns

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub boolean {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $len ) = @$p{qw(logstr name value length)};
    return defined($text) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::column_type::boolean - Transfer plugin for 'boolean' columns

=head1 Interface

=head2 Instance Methods

=head3 C<boolean>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=item C<$len>    field length

=back

The C<boolean> returns 1 for any text...

=cut
