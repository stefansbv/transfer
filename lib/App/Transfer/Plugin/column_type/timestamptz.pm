package App::Transfer::Plugin::column_type::timestamptz;

# ABSTRACT: Transfer plugin for 'timestamptz' columns !STUB!

use 5.010001;
use Moose;
use Try::Tiny;
use Time::Piece;
use namespace::autoclean;

with 'MooX::Log::Any';

sub timestamptz {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $src_format, $src_sep, $is_nullable )
        = @$p{qw(logstr name value src_format src_sep is_nullable)};
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::timestamptz - Transfer plugin for 'timestamptz' columns

=head1 Interface

=head2 Attributes

=head2 Instance Methods

=head3 C<timestamptz>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<timestamptz> method checks the length of the input text and returns
C<undef> if it's different than C<10>, and also creates a log message.
Otherwise tries to transform it to an ISO date and return it.  The
input date format can be from a source configuration option named
C<date_format>.

=cut
