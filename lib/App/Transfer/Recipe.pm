package App::Transfer::Recipe;

# ABSTRACT: Data transformation recipe object

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use Hash::Merge 'merge';
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use App::Transfer::Recipe::Types;            # load first
use App::Transfer::Recipe::Load;
use App::Transfer::Recipe::Header;
use App::Transfer::Recipe::Src;
use App::Transfer::Recipe::Dst;
use App::Transfer::Recipe::Table;
use App::Transfer::Recipe::Transform;
use App::Transfer::Recipe::Datasource;

has 'recipe_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_recipe_data' => (
    is       => 'ro',
    isa      => 'HashRef',
    reader   => 'recipe_data',
    lazy     => 1,
    required => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        return App::Transfer::Recipe::Load->new(
            recipe_file => $self->recipe_file )->load;
    },
);

has header => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Header',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Header->new(
            $self->recipe_data->{recipe} ) if $self->recipe_data->{recipe};
        hurl header => __x( 'The recipe must have a recipe section.' );
    },
);

has 'source' => (
    is       => 'ro',
    isa      => 'App::Transfer::Recipe::Src',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        return App::Transfer::Recipe::Src->new(
            $self->recipe_data->{config}{source} )
            if $self->recipe_data->{config}{source};
        hurl source =>
            __x( "The recipe must have a 'config' section with a 'source' subsection." );
    },
);

has 'destination' => (
    is       => 'ro',
    isa      => 'Maybe[App::Transfer::Recipe::Dst]',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        return App::Transfer::Recipe::Dst->new(
            $self->recipe_data->{config}{destination} )
            if $self->recipe_data->{config}{destination};
        hurl destination =>
            __x( "The recipe must have a 'config' section with a 'destination' subsection." );
    },
);

has 'target' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    lazy     => 1,
    init_arg => undef,
    default => sub {
        my $self    = shift;
        my $tg_href = $self->recipe_data->{config}{target};
        return { map { $_ => $tg_href->{$_}{uri} } keys %{$tg_href} };
    },
    handles  => {
        get_uri => 'get',
    },
);

has tables => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Table',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Table->new(
            $self->recipe_data->{tables} );
    },
);

has transform => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Transform',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Transform->new(
            $self->recipe_data->{transform} );
    },
);

has datasource => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Datasource',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Datasource->new(
            $self->recipe_data->{datasources} );
    },
);


has 'io_trafo_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $prefix = $self->in_type;
        my $sufix  = $self->out_type;
        return "${prefix}2${sufix}";
    },
);

has 'in_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $reader = $self->source->reader;
        my $prefix = $reader;
        $prefix = 'file' if $reader eq 'excel' or $reader eq 'csv';
        return $prefix;
    },
);

has 'out_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $writer = $self->destination->writer;
        my $sufix  = $writer;
        $sufix  = 'file' if $writer eq 'excel' or $writer eq 'csv';
        return $sufix;
    },
);

# XXX
# $self->comment( __x 'No column transforms in recipe.' );
# hurl trafo_type => __x( "Trafo type {type} not implemented", type => $type );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    # XXX Fix message
    hurl destination =>
        __x( "The recipe must have a 'recipe_file' attribute" )
        unless length( $p->{recipe_file} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
