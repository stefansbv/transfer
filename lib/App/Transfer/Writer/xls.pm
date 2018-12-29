package App::Transfer::Writer::xls;

# ABSTRACT: Writer for xls files

use 5.010;
use Moose;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use List::Util qw(any);
use Path::Tiny;
use Try::Tiny;
use Spreadsheet::Wright;
use Data::Dump;
use namespace::autoclean;

extends 'App::Transfer::Writer';
with    'App::Transfer::Role::Utils';

has 'output_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    lazy     => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        my $file = $self->writer_options->file;
        return $file;
    },
);

has 'output_path' => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->writer_options->path || '.';
    },
);

has 'output' => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return path $self->output_path, $self->output_file;
    },
);

has 'header' => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has 'sheet_name' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return 'Sheet1';
    },
);

#---

has 'doc' => (
    is       => 'ro',
    isa      => 'Spreadsheet::Wright',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $ssw  = Spreadsheet::Wright->new(
            file   => $self->output->stringify,
            sheet  => $self->sheet_name,
            styles => {
                header_row => { font_weight => 'bold' },
                mynumber   => { format      => '#,##0.00' },
            },
          );
        hurl __x( 'Cannot create xls (Spreadsheet::Wright): {err}',
                  err => $ssw->error ) if $ssw->error;
        return $ssw;
    },
);

# TODO: custom styles
# has '_style' => (
#     is       => 'ro',
#     traits   => ['Hash'],
#     isa      => 'HashRef',
#     lazy     => 1,
#     init_arg => undef,
#     builder  => '_build_styles',
#     handles  => {
#         get_style  => 'get',
#         all_styles => 'keys',
#     },
# );
# sub _build_styles {
#     return {
#         header_row => { font_weight => 'bold' },
#     };
# }

sub insert_header {
    my $self   = shift;
    my $header = $self->header;
    if ($self->debug) {
        say "# header (before insert):";
        ddx $header;
    }
    try {
        $self->doc->addrow({
            style   => 'header_row',
            content => $header,
        });
    }
    catch {
        die "insert: error $_";
    };
}

sub insert {
    my ($self, $row) = @_;
    my $header = $self->header;
    if ($self->debug) {
        say "# record (before insert):";
        ddx $row;
    }
    my @rec;
    foreach my $field (@{$header}) {
        if ( !exists $row->{$field} ) {
            hurl write =>
              __x( "The field '{field}' does not exist in the record", field => $field );
        }
        push @rec, $row->{$field};
    }
    try { $self->doc->addrow(@rec) }
    catch {
        die "insert: error $_";
    };
    $self->inc_inserted;
    return;
}

sub insert_sheet {
    my ($self, $sheet_name) = @_;
    try { $self->doc->addsheet( $sheet_name ) }
    catch {
        die "add_sheet: error $_";
    };
}

sub finish {
    my $self = shift;
    try { $self->doc->close }
    catch {
        die "finish: error $_";
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

App::Transfer::Writer::xls - Writer for xls files

=head1 SYNOPSIS

    my $writer = App::Transfer::Writer->load({
        transfer       => $transfer,
        writer          => 'xls',
        writer_options  => $options,
    });

    # Add a header to the first sheet (the default sheet name is 'Left').
    $writer->header([qw{field1 field2 field3}]);
    $writer->insert_header;

    # Insert a row of data
    $writer->insert(undef, $row_ref);

    Insert a sheet named 'Test_2' and insert a header and a row in it.
    $writer->insert_sheet('Test_2');
    $writer->header([qw{field4 field5 field6}]);
    $writer->insert_header;
    $writer->insert(undef, $another_row_ref);

    $writer->finish;

=head1 DESCRIPTION

App::Transfer::Writer::xls writes a xls file.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 output_file

A file name representing the xls output file.

=head3 header

An array reference holding the column names.

=head3 sheet_name

=head3 doc

=head3 _style

=head2 INSTANCE METHODS

=head3 _build_styles

=head3 insert_header

Insert the header row in the xls.

=head3 insert

Insert a row of table data in the spreadsheet.

=head3 insert_sheet

=head3 finish

Close the output file.

=cut
