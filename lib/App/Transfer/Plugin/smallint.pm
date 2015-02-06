package App::Transfer::Plugin::smallint;

# ABSTRACT: Transfer plugin for 'smallint' columns

use 5.010001;
use Moose;
use Number::Misc ':all';
use Number::Format qw(:subs);
use namespace::autoclean;

has min => (
    is      => 'ro',
    isa     => 'Int',
    default => -32_768,
);

has max => (
    is      => 'ro',
    isa     => 'Int',
    default => 32_767,
);

with 'MooseX::Log::Log4perl';

sub smallint {
    my ( $self, $p ) = @_;
    my ( $logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return unless defined $text;
    if ( is_numeric( $text, convertible => 1 ) ) {
        $text = to_number($text);
        if ( $text < $self->min or $text > $self->max ) {
            $self->log->info(
                "[$logfld=$logidx] smallint: '$field'='$text' outside of range."
            );
        }
        else {
            return $text;
        }
    }
    else {
        $self->log->info(
            "[$logfld=$logidx] smallint: '$field'='$text' is not numeric.");
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::smallint - Transfer plugin for 'smallint' columns

=head1 Interface

=head2 Attributes

=head3 C<min>

The negative minimum value of a small integer.

=head3 C<max>

The pozitive maximum value of a small integer.

=head2 Instance Methods

=head3 C<smallint>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<smallint> method checks if the input text is numeric and in
range and returns C<undef> if not, and also creates a log message.
Otherwise returns C<$text>.

=cut
