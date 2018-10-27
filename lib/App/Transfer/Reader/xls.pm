package App::Transfer::Reader::xls;

# ABSTRACT: Reader for spreadsheet files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use MooseX::Iterator;
use Locale::TextDomain 1.20 qw(App-Transfer);
use List::Util qw(any);
use List::Compare;
use Spreadsheet::Read;
use App::Transfer::X qw(hurl);
use namespace::autoclean;

use Data::Dump qw/dump/;

extends 'App::Transfer::Reader';

has 'input_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        return $self->options->file;
    },
);

has 'worksheet' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 1 },
);

has 'rectangle' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has 'rect_o' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ( $top, $bot ) = @{ $self->rectangle };
        my ( $col, $row ) = $self->sheet->cell2cr($top);
        return [$col, $row];
    },
);

has 'rect_v' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ( $top, $bot ) = @{ $self->rectangle };
        my ( $col, $row );
        if ( $bot eq 'END' ) {
            $col = $self->sheet->maxcol;
            $row = $self->sheet->maxrow;
        }
        else {
            ( $col, $row ) = $self->sheet->cell2cr($bot);
        }
        return [$col, $row];
    },
);

has 'workbook' => (
    is      => 'ro',
    isa     => 'Spreadsheet::Read',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Spreadsheet::Read->new(
            $self->input_file->stringify,
            clip => 1,
        );
    },
);

has 'sheet' => (
    is      => 'ro',
    isa     => 'Spreadsheet::Read::Sheet',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->workbook->sheet( $self->worksheet );
    },
);

sub _read_rectangle {
    my $self   = shift;
    my $header = $self->header;
    my ( $col_min, $row_min ) = ( $self->rect_o->[0], $self->rect_o->[1] );
    my ( $col_max, $row_max ) = ( $self->rect_v->[0], $self->rect_v->[1] );
    my $col = $self->sheet->maxcol;
    say "# row_min = $row_min  row_max = $row_max" if $self->debug;
    say "# col_min = $col_min  col_max = $col_max" if $self->debug;
    my @aoh = ();
    for my $row_cnt ( $row_min .. $row_max ) {
        my @row = $self->sheet->row($row_cnt);
        my $rec = {};
        my ( $col_idx, $fld_idx ) = ( -1, 0 );
        foreach my $col_cnt ( 1 .. $col ) {
            $col_idx++;
            next if $col_cnt < $col_min;
            next if $col_cnt > $col_max;
            if ( my $field = $header->[$fld_idx] ) {
                my $value = $row[$col_idx];
                $rec->{$field} = $value;
            }
            $fld_idx++;
        }
        if ( any { defined($_) } values %{$rec} ) {
            push @aoh, $rec;
            $self->inc_count;
        }
        else {
            $self->inc_skip;
        }
        last if $self->record_skip >= 2;     # XXX maybe add an attribute for max empty records?
    }
    dump @aoh if $self->debug;
    return \@aoh;
}

has _contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents',
);

sub _build_contents {
    my $self = shift;
    my ( $top, $bot ) = @{ $self->rectangle };
    return $self->_read_rectangle( $top, $bot );
}

has 'contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub BUILDARGS {
    my $class = shift;
    my $p     = shift;
    hurl xls => __ "For the 'xls' reader, the table section must have a 'rectangle' attribute"
                unless length( $p->{rectangle} // '' );
    return $p;
}

sub BUILD {
    my $self = shift;
    my ( $top,     $bot )     = @{ $self->rectangle };
    my ( $col_min, $row_min ) = ( $self->rect_o->[0], $self->rect_o->[1] );
    my ( $col_max, $row_max ) = ( $self->rect_v->[0], $self->rect_v->[1] );
    my $count = scalar @{ $self->header };
    my $range = $col_max - $col_min + 1;
    hurl xls => __x(
        "The columns range ({range}) from the 'rectangle' attribute must match the fields count ({count})",
        range => $range,
        count => $count,
    ) if $range != $count;
    hurl xls => __x(
        "For the 'xls' reader, a valid 'rectangle' attribute with positive row range is required {min} < {max}",
        min => $row_min,
        max => $row_max,
    ) if $row_max <= $row_min;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader::xls - Reader for MSExcel files

=head1 Synopsis

  my $reader = App::Transfer::Reader->load( { reader => 'xls' } );

=head1 Description

App::Transfer::Reader::xls reads an MSExcel file worksheet and
builds a AoH data structure for the entire contents.

=head1 Interface

=head2 Attributes

=head3 C<input_file>

A L<Path::Tiny::File> object representing the xls input file.

=head3 C<worksheet>

The name of the xls worksheet to read from.  It is a C<source> section
attribute in the recipe.  Defaults to 1, the first sheet in the file.

=head3 C<workbook>

The L<Spreadsheet::Read> object instance.

=head3 C<sheet>

The L<Spreadsheet::Read::Sheet> object instance.

=head3 C<_contents>

An array reference holding the contents of the spreadsheet.

=head3 C<contents_iter>

A L<MooseX::Iterator> object for the contents of the xls file.

A L<Spreadsheet::Read> object.

=head2 Instance Methods

=head3 _read_rectangle

Read a data rectangle defined by two points and return it as a AoH.
The points represent the upper left corner of the rectangle and the
lower right corner, respectively.

    my ( $col_min, $row_min ) = ( $self->rect_o->[0], $self->rect_o->[1] );
    my ( $col_max, $row_max ) = ( $self->rect_v->[0], $self->rect_v->[1] );

=head3 _build_contents

The builder method for the C<_contents> attribute.

=cut
