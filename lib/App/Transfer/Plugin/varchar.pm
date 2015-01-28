package App::Transfer::Plugin::varchar;

# ABSTRACT: varchar

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub varchar {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $value, $len ) = @$p{qw(logfld logidx name value length)};
    return unless $value;
    my $str_len = length $value;
    if ($str_len > $len) {
        $self->log->info("[$logfld=$logidx] varchar: $field='$value' overflow ($str_len > $len)");
        return;
    }
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
