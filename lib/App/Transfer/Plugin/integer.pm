package App::Transfer::Plugin::integer;

# ABSTRACT: Transfer plugin for 'integer' columns

use 5.010001;
use Moose;
use Number::Misc ':all';
use MooseX::Params::Validate;
use namespace::autoclean;

with 'MooX::Log::Any';

sub integer {
    my ( $self, %p ) = validated_hash(
        \@_,
        logstr      => { isa => 'Str' },
        pos         => { isa => 'Int' },
        is_nullable => { isa => 'Maybe[Str]' },
        type        => { isa => 'Maybe[Str]' },
        name        => { isa => 'Str' },
        value       => { isa => 'Any' },
        defa        => { isa => 'Maybe[Str]' },
        length      => { isa => 'Maybe[Int]' },
        prec        => { isa => 'Maybe[Int]' },
        scale       => { isa => 'Maybe[Int]' },
    );
    my ( $logstr, $field, $text ) = @p{qw(logstr name value)};
    return unless defined $text;
    is_numeric( $text, convertible => 1 )
        ? return to_number($text)
        : $self->log->info("$logstr integer: $field='$text' is not numeric\n");
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::integer - Transfer plugin for 'integer' columns

=head1 Interface

=head2 Instance Methods

=head3 C<integer>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<integer> method checks if the input text is numeric and returns
C<undef> if not, and also creates a log message.  Otherwise returns
C<$text>.

=cut
