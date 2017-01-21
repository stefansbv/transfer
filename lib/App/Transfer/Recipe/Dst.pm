package App::Transfer::Recipe::Dst;

# ABSTRACT: Recipe section: config/destination

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'writer' => ( is => 'ro', isa => 'Str', required => 1 );

has 'file'   => ( is => 'ro', isa => 'Str' );

has 'target' => ( is => 'ro', isa => 'Str' );

has 'table' => ( is => 'ro', isa => 'Str' );

has 'structure' => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;
    my $p     = shift;
    hurl source =>
        __x( "The destination section must have a 'writer' attribute" )
        unless length( $p->{writer} // '' );
    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Dst - Recipe section: config/destination

=head1 Synopsis

   my $destination = App::Transfer::Recipe::Dst->new(
            $self->recipe_data->{config}{destination} );

=head1 Description

An object representing C<destination> subsection of the C<config>
section of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Dst> object.

   my $destination = App::Transfer::Recipe::Dst->new(
            $self->recipe_data->{config}{source} );

=head2 Attributes

=head3 C<writer>

The name of the writer.  Currently implemented writers:

=over

=item C<db>

Write to a database.

=back

=head3 C<file>

Relevant only for file type writers.  Not used yet.

=head3 C<target>

The name of the database target configuration.

=head3 C<table>

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
