package App::Transfer::Plugin::column_type::timestamp;

# ABSTRACT: Transfer plugin for 'timestamp' columns

use 5.010001;
use Moose;
use Try::Tiny;
use Time::Piece;
use namespace::autoclean;

with 'MooX::Log::Any';

sub format_dmy {
    my ($self, $sep) = @_;
    die "Separator parameter required for 'format_dmy'" unless $sep;
    return '%d' . $sep . '%m' . $sep . '%Y';
}

sub format_mdy {
    my ($self, $sep) = @_;
    die "Separator parameter required for 'format_mdy'" unless $sep;
    return '%m' . $sep . '%d' . $sep . '%Y';
}

sub timestamp {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $src_format, $src_sep, $is_nullable )
        = @$p{qw(logstr name value src_format src_sep is_nullable)};
    unless ($text) {
        unless ($is_nullable) {
            my $log_text = defined $text ? '' : 'undef';
            $self->log->error(
                "$logstr date: $field='$log_text' - date is not nullable!");
            return;
        }
        return;
    }
    if (length $text < 18) {
        $self->log->info("$logstr date: $field='$text' is not a >18 character date time\n");
        return;
    }
    my $meth = "${src_format}_to_iso";
    if ( $self->can($meth) ) {
        my ($date, $time) = split /[T,;\s]\s?/, $text;
        return $self->$meth($field, $date, $time, $logstr, $src_sep);
    }
    else {
        $self->log->error(
            "$logstr date: $field='$text' - $meth method not implemented!");
    }
}

sub iso_to_iso {
    my ($self, $field, $date, $time, $logstr) = @_;
    return unless $date;
    if ( $date !~ /\d{4}-\d{2}-\d{2}/ ) {
        $self->log->info(
            "$logstr date: $field='$date' is not a valid ISO date");
        return undef;
    }
    return qq(${date}T${time});
}

sub dmy_to_iso {
    my ($self, $field, $date, $time, $logstr, $sep) = @_;
    return unless $date;
    my $dt = try { Time::Piece->strptime( $date, $self->format_dmy($sep) ) }
    catch {
        $self->log->info(
            "$logstr date: $field='$date' is not a valid DMY date");
        return undef;
    };
    return unless $dt;
    $date = $dt->ymd;                         # iso
    return qq(${date}T${time});
}

sub mdy_to_iso {
    my ($self, $field, $date, $time, $logstr, $sep) = @_;
    return unless $date;
    my $dt = try { Time::Piece->strptime( $date, $self->format_mdy($sep) ) }
    catch {
        $self->log->info(
            "$logstr date: $field='$date' is not a valid DMY date");
        return undef;
    };
    return unless $dt;
    $date = $dt->ymd;                         # iso
    return qq(${date}T${time});
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::timestamp - Transfer plugin for 'timestamp' columns

=head1 Interface

=head2 Attributes

=head3 C<format_dmy>

The DMY format for parsing dates with the C<Time::Piece> module.  The
default separator is the "." character.

=head3 C<format_mdy>

The MDY format for parsing dates with the C<Time::Piece> module.  The
default separator is the "/" character.

=head2 Instance Methods

=head3 C<timestamp>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=back

The C<timestamp> method checks the length of the input text and returns
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

Takes an European formated timestamp string and return an ISO timestamp.

=cut
