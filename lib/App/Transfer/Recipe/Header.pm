package App::Transfer::Recipe::Header;

# ABSTRACT: Recipe section: recipe (the header)

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'version'       => ( is => 'ro', isa => 'Natural', required => 1 );
has 'syntaxversion' => ( is => 'ro', isa => 'NaturalLessThanN', required => 1 );
has 'name'          => ( is => 'ro', isa => 'Str' );
has 'description'   => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)
    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    hurl source =>
        __x("The recipe must have a valid 'version' attribute")
            unless length( $p->{version} // '' );
    hurl source =>
        __x("The recipe must have a valid 'syntaxversion' attribute")
            unless length( $p->{syntaxversion} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Header - Recipe section: recipe

=head1 Synopsis

  my $tables = App::Transfer::Recipe::Header->new(
      $self->recipe_data->{recipe},
  );

=head1 Description

An object representing the C<recipe> header section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Header> object.

  my $header = App::Transfer::Recipe::Header->new(
      $self->recipe_data->{recipe},
  );

=head2 Attributes

=head3 C<header>

Returns an object instance representing the C<recipe> header section
of the recipe.

=over

=item version

The version of the recipe.

=item syntaxversion

The syntax version of the recipe.  Currently is C<1>.  This is
required to be set.

=item name

The name of the recipe.

=item description

A description of the recipe.

=back

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
