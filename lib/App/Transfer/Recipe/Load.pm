package App::Transfer::Recipe::Load;

# ABSTRACT: Load a recipe data structure

use 5.014;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use Try::Tiny;
use Config::General;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use constant SYNTAX_VERSION => 2;

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has 'load' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $file = $self->recipe_file;
        my $conf = try {
            Config::General->new(
                -UTF8            => 1,
                -ForceArray      => 1,
                -ConfigFile      => $file,
                -IncludeRelative => 1,
                -FlagBits        => {
                    attributes => {
                        APPEND          => 1,
                        APPENDSRC       => 1,
                        COPY            => 1,
                        MOVE            => 1,
                        REPLACE         => 1,
                        REPLACENULL     => 1,
                        IGNORECASE      => 1,
                        IGNOREDIACRITIC => 1,
                        REGEX           => 1,
                    },
                },
            );
        }
        catch {
            hurl source => __x(
                "Failed to load the recipe file '{file}': {error}",
                file  => $file,
                error => $_,
            );
        };
        my %config = $conf->getall;
        $self->validate_recipe_sections(\%config);
        return \%config;
    }
);

sub validate_recipe_sections {
    my ( $self, $p ) = @_;

    hurl header => __("The recipe must have a 'recipe' section.")
        if !exists $p->{recipe};

    hurl recipe =>
        __x( "The recipe must have a valid 'syntaxversion' attribute (the current version is {sv})",
             sv => SYNTAX_VERSION )
        if !exists $p->{recipe}{syntaxversion}
        || $p->{recipe}{syntaxversion} eq ""
        || $p->{recipe}{syntaxversion} != SYNTAX_VERSION;

    hurl source => __(
        "The recipe must have a 'config' section with a 'source' subsection."
    ) if !exists $p->{config}{source};

    hurl destination => __(
        "The recipe must have a 'config' section with a 'destination' subsection."
    ) if !exists $p->{config}{destination};

    hurl table => __( "The recipe must have a 'table' section." )
        if !exists $p->{table};

    hurl recipe =>
        __x( "The v{sv} recipe 'tables' section was replaced by 'table'",
             sv => SYNTAX_VERSION )
        if exists $p->{tables};

    # my ( $name, $meta ) = each %{ $p->{table} };
    # hurl recipe =>
    #     __x( "The v{sv} recipe table section must have a 'header' attribute instead of 'headermap'",
    #          sv => SYNTAX_VERSION )
    #     if exists $meta->{headermap};

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Load - Load a recipe data-structure

=head1 Synopsis

   my $recipe_data = App::Transfer::Recipe::Load->new(
       recipe_file => $recipe_file )->load;

=head1 Description

Load a recipe data structure from a recipe file.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Load> object.

   my $recipe = App::Transfer::Recipe::Load->new(
       recipe_file => $recipe_file,
   );
   my $recipe_data = $recipe->load;

=head2 Attributes

=head3 C<recipe_file>

The path to the recipe file.

=head3 C<load>

Loads and returns a data structure representing the configuration of
the recipe.

=head3 C<validate_recipe_sections>

If the keys of the hash coresponding to the main sections of the
recipe doesn't exists, throw exceptions.

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
