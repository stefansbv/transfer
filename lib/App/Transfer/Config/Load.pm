package App::Transfer::Config::Load;

# ABSTRACT: Load configurations

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use Config::General;

has 'header_map_file' => (
    is  => 'ro',
    isa => 'Path::Class::File',
);

has 'load' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $conf_gen = Config::General->new(
            -UTF8       => 1,
            -ForceArray => 1,
            -ConfigFile => $self->header_map_file,
        );
        my %config = $conf_gen->getall;
        return \%config;
    }
);

__PACKAGE__->meta->make_immutable;

1;
