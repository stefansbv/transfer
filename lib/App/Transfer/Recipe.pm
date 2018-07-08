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

#-  Sections

#-- Recipe (header)

has 'header' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Header',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Header->new(
            $self->recipe_data->{recipe} );
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
            $self->recipe_data->{config}{source} );
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
            $self->recipe_data->{config}{destination} );
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

#-- Table

has 'table' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe::Table',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %kv   = %{ $self->recipe_data->{table} };
        my $cnt  = scalar keys %kv;
        hurl recipe => __x( "Expecting a table not '{cnt}'!", cnt => $cnt )
            if $cnt > 1;
        my ( $name, $meta ) = each %kv;
        if ( $name and ref $meta ) {
            my $header = delete $meta->{header}{field};
            $meta->{header} = $header;
            return App::Transfer::Recipe::Table->new(
                name => $name,
                %{$meta},
            );
        }
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
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe::Datasource->new(
            $self->recipe_data->{datasources},
        );
    },
);

#-  Sections end

has 'in_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $reader = $self->source->reader;
        my $prefix = $reader;
        $prefix = 'file'
            if $reader eq 'xls'
            or $reader eq 'csv'
            or $reader eq 'dbf'
            or $reader eq 'odt';
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
        $sufix  = 'file' if $writer eq 'xls' or $writer eq 'csv' or $writer eq 'dbf';
        return $sufix;
    },
);

sub BUILDARGS {
    my $class = shift;
    my $p     = { @_ };
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

=head3 C<table>

Returns an object instance representing the C<table> section of the
recipe.

=head3 C<transform>

Returns an object instance representing the C<transform> section of
the recipe.

=head3 C<datasource>

Returns an object instance representing the C<datasource> section of
the recipe.

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

Returns the string C<file> if the reader is set to C<xls> or <csv>,
or the value of the reader, C<db> is the only valid value..

=head3 C<out_type>

Returns the string C<file> if the writer is set to C<xls> or <csv>,
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
