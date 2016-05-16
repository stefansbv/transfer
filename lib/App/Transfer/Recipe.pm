package App::Transfer::Recipe;

# ABSTRACT: Data transformation recipe object

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use App::Transfer::Recipe::Types;            # load first
use App::Transfer::Recipe::Load;
use App::Transfer::Recipe::Header;
use App::Transfer::Recipe::Src;
use App::Transfer::Recipe::Dst;
use App::Transfer::Recipe::Tables;
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

#-  Sections

#-- Recipe (header)

has 'header' => (
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

#-- Config

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

#-- Tables

has 'tables' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Tables',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Tables->new(
            $self->recipe_data->{tables} );
    },
);

#-- Transformations

has 'transform' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Transform',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Transform->new(
            $self->recipe_data->{transform} );
    },
);

#-- Data sources

has 'datasource' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Datasource',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Datasource->new(
            $self->recipe_data->{datasources} );
    },
);

#-  Sections end

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

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    hurl "Missing 'recipe_file' attribute"
        unless length( $p->{recipe_file} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe - Recipe object

=head1 Synopsis

  my $recipe = App::Transfer::Recipe->new(
     recipe_file => './recipe-test.conf',
  );

=head1 Description

An object representing the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe> object.

  my $recipe = App::Transfer::Recipe->new(
     recipe_file => $recipe_file,
  );

The parameters:

=over

=item C<recipe_file>

The path to the recipe file.

=back

=head2 Attributes

=head3 C<recipe_file>

The file with the recipe configuration.

=head3 C<_recipe_data>

The C<_recipe_data> attribute holds the data-structure of the recipe.
It is a hash reference and the keys are the names of the recipe
sections.

=head3 C<header>

Returns an object instance representing the C<header> section of the
recipe.

=head3 C<source>

Returns an object instance representing the C<source> subsection of
the C<config> section of the recipe.

=head3 C<destination>

Returns an object instance representing the C<destination> subsection of
the C<config> section of the recipe.

=head3 C<target>

Returns an hash reference representing the C<target> subsection of the
C<config> section of the recipe.

=head3 C<tables>

Returns an object instance representing the C<tables> section of the
recipe.

=head3 C<transform>

Returns an object instance representing the C<transform> section of
the recipe.

=head3 C<datasource>

Returns an object instance representing the C<datasource> section of
the recipe.

=head3 C<io_trafo_type>

Returns the string resulted from the concatenation of the C<in_type>
and the C<out_type> attributes:

Valid values:

=over

=item C<file2db>

=item C<db2db>

=item C<file2file> (not implemented, yet)

=item C<db2file>   (not implemented, yet)

=back

Is used by the C<run> command to select and execute the proper
transformation method.

=head3 C<in_type>

Returns the string C<file> if the reader is set to C<excel> or <csv>,
or the value of the reader, C<db> is the only valid value..

=head3 C<out_type>

Returns the string C<file> if the writer is set to C<excel> or <csv>,
or the value of the writer, C<db> is the only valid value..

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
