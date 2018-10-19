package App::Transfer::Plugin::column_type::date_extended;

# ABSTRACT: Transfer plugin for 'date' columns

use 5.010001;
use Moose;
use Try::Tiny;
use Date::Calc qw ( Decode_Date_EU );
use namespace::autoclean;

with 'MooX::Log::Any';

sub date_extended {
    my ($self, $p) = @_;
    my ($logstr, $field, $text ) = @$p{qw(logstr name value)};
    return unless defined $text;
    return if length $text == 0;    # return undef => NULL
    if (length $text != 10) {
        $self->log->info("$logstr date: $field='$text' is not a date\n");
        return;
    }
    return $self->eu_to_iso($field, $text, $logstr);
}

sub eu_to_iso {
    my ($self, $field, $text, $logstr) = @_;
    return unless $text;
    my ( $year, $month, $day ) = Decode_Date_EU($text);
    unless ( $year and $month and $day ) {
        $self->log->info("$logstr date: $field='$text' is not a valid EU date");
        return;
    }
    return sprintf( "%04d\-%02d\-%02d", $year, $month, $day );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::date - Transfer plugin for 'date' columns

=head1 Interface

=head2 Attributes

=head3 C<format_dmy>

The DMY format for parsing dates with the C<Time::Piece> module.  The
default separator is the "." character.

=head3 C<format_mdy>

The MDY format for parsing dates with the C<Time::Piece> module.  The
default separator is the "/" character.

=head2 Instance Methods

=head3 C<date>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<date> method checks the length of the input text and returns
C<undef> if it's different than C<10>, and also creates a log message.
Otherwise tries to transform it to an ISO date and return it.  The
input date format can be from a source configuration option named
C<date_format>.

=head3 C<iso_to_iso>

Empty method for the default date formats: ISOI 8601.

=head3 C<dmy_to_iso>

Convert the date string from DMY to the ISO format.

=head3 C<mdy_to_iso>

Convert the date string from MDY to the ISO format.

=head3 C<eu_to_iso>

Takes an European formated date string and return an ISO date.

=cut
