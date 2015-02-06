package App::Transfer::Recipe::Load;

# ABSTRACT: Load a recipe data structure

use Moose;
use MooseX::FileAttribute;
use Config::General;
use namespace::autoclean;

has_file 'recipe_file' => (
    is         => 'ro',
    must_exist => 1,
    required   => 1,
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
            -ConfigFile => $self->recipe_file,
            -FlagBits   => {
                attributes => {
                    APPEND      => 1,
                    APPENDSRC   => 1,
                    COPY        => 1,
                    MOVE        => 1,
                    REPLACE     => 1,
                    REPLACENULL => 1,
                },
            },
        );
        my %config = $conf_gen->getall;
        return \%config;
    }
);

__PACKAGE__->meta->make_immutable;

1;
