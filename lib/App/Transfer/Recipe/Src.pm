package App::Transfer::Recipe::Src;

# ABSTRACT: Recipe section: config/source

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'reader' => ( is => 'ro', isa => 'Str', required => 1 );
has 'file'   => ( is => 'ro', isa => 'Str' );
has 'target' => ( is => 'ro', isa => 'Str' );
has 'table'  => ( is => 'ro', isa => 'Str' );

has 'date_format' => (
    is       => 'ro',
    isa      => enum( [qw(dmy mdy iso)] ),
    default => sub {
        return 'iso';
    },
);

has 'date_sep' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self        = shift;
        my $date_format = $self->date_format;
        return
              $date_format eq 'dmy' ? '.'
            : $date_format eq 'mdy' ? '/'
            :                         '-';
    },
);

sub BUILDARGS {
    my $class = shift;
    my $p     = shift;
    hurl source =>
        __x( "The source section must have a 'reader' attribute" )
        unless length( $p->{reader} // '' );
    return $p;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Src - Recipe section: config/source

=head1 Synopsis

   my $source = App::Transfer::Recipe::Src->new(
            $self->recipe_data->{config}{source} );

=head1 Description

An object representing C<source> subsection of the C<config> section
of the recipe.

=head1 Interface

=head3 C<new>

Instantiates and returns an L<App::Transfer::Recipe::Src> object.

   my $source = App::Transfer::Recipe::Src->new(
            $self->recipe_data->{config}{source} );

=head2 Attributes

=head3 C<reader>

The name of the reader.  Currently implemented readers:

=over

=item C<db>

Read from a database (Firebird or PostgreSQL).

=item C<xls>

Read from a Microsoft xls file.

=item C<csv>

Read from a CSV file.

=back

=head3 C<file>

Relevant only for file type readers: C<xls> and C<csv>.

=head3 C<target>

The name of the database target configuration.

=head3 C<table>

The name of the database table to read from.

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
