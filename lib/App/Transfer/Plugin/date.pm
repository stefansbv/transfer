package App::Transfer::Plugin::date;

# ABSTRACT: Transfer plugin for 'date' columns

use 5.010001;
use Moose;
use Date::Calc qw ( Decode_Date_EU );
use namespace::autoclean;

with 'MooX::Log::Any';

sub date {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    return unless defined $text;
    return if length $text == 0;    # return undef => NULL
    if (length $text != 10) {
        $self->log->info("[$logfld=$logidx] date: $field='$text' is not a date\n");
        return;
    }
    return $self->eu_to_iso($field, $text, $logfld, $logidx);
}

sub eu_to_iso {
    my ($self, $field, $text, $logfld, $logidx) = @_;
    return unless $text;
    my ( $year, $month, $day ) = Decode_Date_EU($text);
    unless ( $year and $month and $day ) {
        $self->log->info("[$logfld=$logidx] date: $field='$text' is not a valid EU date");
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

=head2 Instance Methods

=head3 C<date>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<date> method checks the length of the input text and returns
C<undef> if it's different than C<10>, and also creates a log message.
Otherwise tries to transform it to an ISO date and return it.  The
input date format is assumed to be in European format.

=head3 C<eu_to_iso>

Takes an European formated date string and return an ISO date.

=cut
