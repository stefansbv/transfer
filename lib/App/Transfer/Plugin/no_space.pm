package App::Transfer::Plugin::no_space;

# ABSTRACT: no space

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub no_space {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value, $len ) = @$p{qw(logfld logidx name value length)};
    return unless $value;
    $value =~ s{\s+}{}gmx;
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
