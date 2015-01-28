package App::Transfer::Plugin::lookup_in_ds;

# ABSTRACT: lookup in data source

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub lookup_in_ds {
    my ( $self, $p ) = @_;
    my ( $logfld, $logidx, $field, $value, $lookup_table )
        = @$p{qw(logfld logidx name value lookup_table)};
    return unless $value;
    foreach my $rec ( @{$lookup_table} ) {
        foreach my $key ( keys %{$rec} ) {
            return $rec->{$key} if $value =~ m{$key};
        }
    }
    $self->log->info("[$logfld=$logidx] lookup: failed for '$field'='$value'");
    return;
}

__PACKAGE__->meta->make_immutable;

1;
