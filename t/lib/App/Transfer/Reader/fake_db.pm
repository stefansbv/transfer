package App::Transfer::Reader::fake_db;

# ABSTRACT: Fake reader for Database engines

use 5.010001;
use Moose;
use MooseX::Iterator;
use namespace::autoclean;

use App::Transfer::Target;
use Test::MockModule;

extends 'App::Transfer::Reader';

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'orderby' => (
    is       => 'ro',
    isa      => 'Str|ArrayRef|HashRef',
    required => 0,
);

has 'filter' => (
    is       => 'ro',
    isa      => 'ArrayRef|HashRef',
    required => 0,
);

has 'target' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $mock = Test::MockModule->new('App::Transfer::Target');
        $mock->mock( transfer => sub { $self->transfer } );
        $mock->mock( uri      => sub { $self->options->uri_str } );
        $mock->mock( name     => sub { $self->options->target } );
        $mock->mock( engine   => sub { say "I AM ENGINE" } );
        return $mock;
    },
);

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my @records;
    foreach my $rec ( @{ $self->get_data } ) {
        push @records, $rec;
        $self->inc_count;
    }
    return \@records;
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub get_data {
    my $self    = shift;
    return [
        {   siruta => 10,
            denloc => "JUDETUL ALBA",
            jud    => 1,
        },
        {   siruta => 1017,
            denloc => "MUNICIPIUL ALBA IULIA",
            jud    => 1,
        },
        {   siruta => 1026,
            denloc => "ALBA IULIA",
            jud    => 1,
        },
    ];
}

sub get_fields {
    my ( $self, $table ) = @_;
    return [qw{siruta denloc jud}];
}

sub validate_header_fields {
    my ($self, $table) = @_;
    my @fields_cm;
    return \@fields_cm;
}

__PACKAGE__->meta->make_immutable;

1;
