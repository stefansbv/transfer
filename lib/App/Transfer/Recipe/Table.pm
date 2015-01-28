package App::Transfer::Recipe::Table;

# ABSTRACT: Data transformation recipe parser

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use App::Transfer::Recipe::Table::HeaderMap;

has 'worksheet' => ( is => 'ro', isa => 'Str' );
has 'lastrow'   => ( is => 'ro', isa => 'Maybe[Int]' );
has 'table'     => ( is => 'ro', isa => 'HashRef', required => 1 );

has '_table_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    traits   => ['Array'],
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my @tables = keys %{ $self->table };
        return \@tables;
    },
    handles  => {
        get_table_name  => 'get',
        all_table_names => 'elements',
        find_table_name => 'first',
    },
);

has '_tables' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my %tables;
        foreach my $name ( keys %{ $self->table } ) {
            $tables{$name} = App::Transfer::Recipe::Table::HeaderMap->new(
                $self->table->{$name}
            );
        }
        return \%tables;
    },
    handles  => {
        get_table => 'get',
    },
);

sub has_table {
    my ($self, $name) = @_;
    die "the name parameter is required!" unless defined $name;
    return $self->find_table_name( sub { /$name/ } );
}

__PACKAGE__->meta->make_immutable;

1;
