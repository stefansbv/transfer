package App::Transfer::Plugin::ro_cnp;

# ABSTRACT: Romanian CNP validation

use 5.010001;
use Moose;
use Business::RO::CNP;
use Try::Tiny;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub ro_cnp {
    my ( $self,  $p )     = @_;
    my ( $logfld, $logidx, $field, $value ) = @$p{qw(logfld logidx name value)};
    return unless $value;
    my $cnp;
    try { $cnp = Business::RO::CNP->new( cnp => $value ) }
    catch {
        $self->log->info("[$logfld=$logidx] warning: $field='$value' is not a valid CNP: $_")
    };
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
