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
