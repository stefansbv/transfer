package App::Transfer::Plugin::first_upper;

# ABSTRACT: first upper

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub first_upper {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless $value;
    return uc substr $value, 0, 1;
}

__PACKAGE__->meta->make_immutable;

1;
