package App::Transfer::Plugin::column_type::date;

# ABSTRACT: Transfer plugin for 'date' columns

use 5.010001;
use Moose;
use Try::Tiny;
use Time::Piece;
use namespace::autoclean;

with 'MooX::Log::Any';

sub format_dmy {
    my ($self, $sep) = @_;
    return '%d' . $sep . '%m' . $sep . '%Y';
}

sub format_mdy {
    my ($self, $sep) = @_;
    return '%m' . $sep . '%d' . $sep . '%Y';
}

sub date {
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
    if (length $text != 10) {
        $self->log->info("$logstr date: $field='$text' is not a 10 character date\n");
        return;
    }
    my $meth = "${src_format}_to_iso";
    if ( $self->can($meth) ) {
        return $self->$meth($field, $text, $logstr, $src_sep);
    }
    else {
        $self->log->error(
            "$logstr date: $field='$text' - $meth method not implemented!");
    }
}

sub iso_to_iso {
    my ($self, $field, $text, $logstr) = @_;
    # Just return the value.
    if ( $text !~ /\d{4}-\d{2}-\d{2}/ ) {
        $self->log->info(
            "$logstr date: $field='$text' is not a valid ISO date");
        return undef;
    }
    return $text;
}

sub dmy_to_iso {
    my ($self, $field, $text, $logstr, $sep) = @_;
    return unless $text;
    my $dt = try { Time::Piece->strptime( $text, $self->format_dmy($sep) ) }
    catch {
        $self->log->info(
            "$logstr date: $field='$text' is not a valid DMY date");
        return undef;
    };
    return unless $dt;
    return $dt->ymd;                         # iso
}

sub mdy_to_iso {
    my ($self, $field, $text, $logstr, $sep) = @_;
    return unless $text;
    my $dt = try { Time::Piece->strptime( $text, $self->format_mdy($sep) ) }
    catch {
        $self->log->info(
            "$logstr date: $field='$text' is not a valid MDY date");
        return undef;
    };
    return unless $dt;
    return $dt->ymd;                         # iso
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
