package App::Transfer::Plugin::null_ifzero;

# ABSTRACT: null if zero

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub null_ifzero {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return if not defined $value;
    return if $value == 0;
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
