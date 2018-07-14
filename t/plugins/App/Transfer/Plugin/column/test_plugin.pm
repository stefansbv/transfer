package App::Transfer::Plugin::column::test_plugin;

# ABSTRACT: test plugin

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub test_plugin {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text ) = @$p{qw(logfld logidx name value)};
    $self->log->info("test plugin loaded");
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
