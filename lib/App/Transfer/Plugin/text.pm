package App::Transfer::Plugin::text;

# ABSTRACT: text

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub text {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless $value;
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
