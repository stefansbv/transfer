package App::Transfer::Plugin::split_field;

# ABSTRACT: split_field

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub split_field {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value, $limit, $separator )
        = @$p{qw(logfld logidx name value limit separator)};
    return unless $value;
    return split /$separator/, $value, $limit;
}

__PACKAGE__->meta->make_immutable;

1;
