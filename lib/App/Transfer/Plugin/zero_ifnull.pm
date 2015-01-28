package App::Transfer::Plugin::zero_ifnull;

# ABSTRACT: zero if not defined

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub zero_ifnull {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return 0 if not defined $value;
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
