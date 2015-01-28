package App::Transfer::Plugin::date;

# ABSTRACT: date

use 5.010001;
use Moose;
use Date::Calc qw ( Decode_Date_EU );
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub date {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless defined $value;
    return if length $value == 0;    # return undef => NULL
    if (length $value != 10) {
        $self->log->info("[$logfld=$logidx] date: $field='$value' is not a date\n");
        return;
    }
    return $self->eu_to_iso($field, $value, $logfld, $logidx);
}

sub eu_to_iso {
    my ($self, $field, $value, $logfld, $logidx) = @_;
    return unless $value;
    my ( $year, $month, $day ) = Decode_Date_EU($value);
    unless ( $year and $month and $day ) {
        $self->log->info("[$logfld=$logidx] date: $field='$value' is not a valid date");
        return;
    }
    return sprintf( "%04d\-%02d\-%02d", $year, $month, $day );
}

__PACKAGE__->meta->make_immutable;

1;
