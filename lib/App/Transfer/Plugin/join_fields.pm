package App::Transfer::Plugin::join_fields;

# ABSTRACT: join_fields

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub join_fields {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value, $separator ) = @$p{qw(logfld logidx name value separator)};
    return unless ref $value;
    return join $separator, @{$value};
}

__PACKAGE__->meta->make_immutable;

1;
