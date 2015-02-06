package App::Transfer::Plugin::char;

# ABSTRACT: Transfer plugin for 'char' columns

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub char {
    my ( $self, $p ) = @_;
    my ( $logfld, $logidx, $field, $text, $len )
        = @$p{qw(logfld logidx name value length)};
    return unless defined $text;
    my $str_len = length $text;
    if ( $str_len > $len ) {
        $self->log->info(
            "[$logfld=$logidx] char: $field='$text' overflow ($str_len > $len)"
        );
        return;
    }
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::char - Transfer plugin for 'char' columns

=head1 Interface

=head2 Instance Methods

=head3 C<char>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=item C<$len>    field length

=back

The C<char> method checks the length of the input text and returns
C<undef> if it's longer than C<$len>, and also creates a log message.
Otherwise returns C<$text>.

=cut
