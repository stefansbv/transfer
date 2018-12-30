package App::Transfer::Plugin::column_type::float;

# ABSTRACT: Transfer plugin for 'float' columns

use 5.010001;
use Moose;
use Number::Misc ':all';
use namespace::autoclean;

with 'MooX::Log::Any';

sub float {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $prec, $scale )
        = @$p{qw(logstr name value prec scale)};
    return unless defined $text;
    is_numeric( $text, convertible => 1 )
        ? return to_number($text)
        : $self->log->info("$logstr float: $field='$text' is not numeric\n");
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::float - Transfer plugin for 'float' columns

=head1 Interface

=head2 Instance Methods

=head3 C<float>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<float> method checks if the input text is numeric and returns
C<undef> if not, and also creates a log message.  Otherwise returns
C<$text>.

=cut
