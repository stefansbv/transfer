package App::Transfer::Plugin::column_type::array;

# ABSTRACT: Transfer plugin for 'array' columns

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub array {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $len ) = @$p{qw(logstr name value length)};
    return unless $text;
    warn "Pg array column type not implemented!";
    # my @ret = split /[;,]/, $text;
    # print " ret:\n";
    # use Data::Dump; dd @ret;
    # return \@ret;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::array - Transfer plugin for 'array' columns

=head1 Interface

=head2 Instance Methods

=head3 C<array>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=item C<$len>    field length

=back

The C<array> method ...

=cut
