package App::Transfer::Plugin::column::year_from_filename;

# ABSTRACT: Transfer plugin: value for field from file name (XXXXyymm)

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub year_from_filename {
    my ( $self, $p ) = @_;
    my ( $logstr, $text, $len ) = @$p{qw(logstr value length)};
    return unless $text;
    if ( $text =~ m/\w{4}\d{4}/ ) {
        my $value = substr( $text, 4, 2 );
        return "20" . $value;
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
