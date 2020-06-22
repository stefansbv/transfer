package App::Transfer::Plugin::column::day_from_filename;

# ABSTRACT: Transfer plugin: value for field from file name (TMYYMMZZ)

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub day_from_filename {
    my ( $self, $p ) = @_;
    my ( $logstr, $text, $pat ) = @$p{qw(logstr value pattern)};
    return unless $text;
    die "The 'day_from_filename plugin' requires a pattern attribute"
        unless $pat;
    if ( my ( $i, $l ) = $self->params_from_pattern($pat) ) {
        my $value = substr( $text, $i, $l );
        return $value;
    }
    return;
}

sub params_from_pattern {
    my ( $self, $pat ) = @_;
    my $p1 = index $pat, '[';
    if ( $p1 > 0 ) {
        my $p2 = index $pat, ']';
        return ( $p1, $p2 - 1 - $p1 );
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Plugin::day_from_filename - plugin: 'day_from_filename'

Example recipe configuration:

Transformation step (column):

    <transform column>
      <step>
        type                = default_value
        pattern             = TMYYMM[dd]
        field               = day
        method              = day_from_filename
      </step>
    </transform>

=head1 INTERFACE

=head2 INSTANCE METHODS

=head3 C<day_from_filename>

Parameters:

=over

=item C<$logstr> log string

=item C<$text>   value

=item C<$pat>    pattern

=back

The C<day_from_filename> method returns the number extracted from the
input C<value> using the C<pattern> parameter.

The C<pattern> is a string which provides the position of the text to
be returned.  A '[' and a ']' character mark the substring to be
returned.

For example if we have a file name like C<TM200331> (without the
extension) and a pattern like C<TMYYMM[dd]>, we expect the number 31
to be returned by the function.

The method can be extended with validation code to check if the file
name starts with C<TM> and if the return string is a number or even a
valid day number.

=head3 C<params_from_pattern>

The C<params_from_pattern method> calculates and returns the index and
the lenght parameters for the substr function.

Example:

    pattern = TMYYMM[dd]
      -> p1 = 6
      -> p2 = 9
        => (6, 2)

=cut
