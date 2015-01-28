package App::Transfer::Plugin::words_first_upper;

# ABSTRACT: words first upper

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub words_first_upper {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless $value;
    my @words = map { ucfirst $_ } split /[-\s]/, $value;
    return join ' ', @words;
}

__PACKAGE__->meta->make_immutable;

1;
