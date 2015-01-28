package App::Transfer::Plugin::smallint;

# ABSTRACT: smallint

use 5.010001;
use Moose;
use Number::Misc ':all';
use Number::Format qw(:subs);
use namespace::autoclean;

has min => (
    is      => 'ro',
    isa     => 'Int',
    default => -32_768,
);

has max => (
    is      => 'ro',
    isa     => 'Int',
    default => 32_767,
);

with 'MooseX::Log::Log4perl';

sub smallint {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless defined $value;
    if ( is_numeric( $value, convertible => 1 ) ) {
        $value = to_number($value);
        if ( $value < $self->min or $value > $self->max ) {
            $self->log->info("[$logfld=$logidx] smallint: '$field'='$value' outside of range.");
        }
        else {
            return $value;
        }
    }
    else {
        $self->log->info("[$logfld=$logidx] smallint: '$field'='$value' is not numeric.");
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
