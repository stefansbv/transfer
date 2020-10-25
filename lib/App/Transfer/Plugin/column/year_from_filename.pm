package App::Transfer::Plugin::column::year_from_filename;

# ABSTRACT: Transfer plugin: value for field from file name (TMyymmzz)

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub year_from_filename {
    my ( $self, $p ) = @_;
    my ( $logstr, $text, $len, $pat ) = @$p{qw(logstr value length pattern)};
    return unless $text;
    die "The 'month_from_filename plugin' requires a pattern attribute" unless $pat;
    my ($i, $l) = $self->params_from_pattern($pat);
    my $value = '20' . substr( $text, $i, $l );
    return $value;
}

# pattern = TM[dd]MMDD
# -> p1 = 2 |
# -> p2 = 5 | => (2, 2)
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

App::Transfer::Plugin::year_from_filename - plugin: 'year_from_filename'

=head1 INTERFACE

=head2 INSTANCE METHODS

=head3 C<one_space>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<one_space> method replaces all space chars (regex: \s+) with a
single space and returns the resulting string.

=cut
