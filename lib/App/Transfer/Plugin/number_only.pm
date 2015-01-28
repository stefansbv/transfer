package App::Transfer::Plugin::number_only;

# ABSTRACT: number only

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub number_only {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless $value;
    $value =~ s{[^\d.]+}{}g;
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
