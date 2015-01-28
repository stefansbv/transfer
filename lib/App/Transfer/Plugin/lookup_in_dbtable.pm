package App::Transfer::Plugin::lookup_in_dbtable;

# ABSTRACT: lookup in database table

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub lookup_in_dbtable {
    my ( $self, $p ) = @_;
    my ($logfld, $logidx, $fields, $table, $engine, $where, $lookup)
        = @$p{qw(logfld logidx fields table engine where lookup)};
    return unless $lookup;

    my $result_aref = $engine->lookup( $table, $fields, $where );
    my $ret_no = scalar @{$result_aref};
    if ( $ret_no == 1 ) {
        return $result_aref->[0];
    }
    elsif ( $ret_no > 1 ) {
        my $results = '';
        foreach my $ary (@{$result_aref}) {
            $results .= ' ';
            $results .= "'" . join( ',', @{$ary} ) . "'";
        }
        $self->log->info(
            "[$logfld=$logidx] lookup: multiple values for '",
            join( ',', @{$fields} ), "'='$lookup': $results"
        );
    }
    else {
        $self->log->info(
            "[$logfld=$logidx] lookup: failed for '",
            join( ',', @{$fields} ), "'='$lookup'" );
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
