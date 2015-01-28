package App::Transfer::Plugin::integer;

# ABSTRACT: integer

use 5.010001;
use Moose;
use Number::Misc ':all';
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub integer {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless defined $value;
    is_numeric( $value, convertible => 1 )
        ? return to_number($value)
        : $self->log->info("[$logfld=$logidx] integer: $field='$value' is not numeric\n");
    return;
}

__PACKAGE__->meta->make_immutable;

1;
