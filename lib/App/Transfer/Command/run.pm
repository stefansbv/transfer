package App::Transfer::Command::run;

# ABSTRACT: Process a recipe file

use 5.010001;
use utf8;

use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use MooseX::Iterator;
use Locale::TextDomain qw(App-Transfer);
use Path::Class;
use App::Transfer::X qw(hurl);
use Perl6::Form;
use namespace::autoclean;

extends qw(App::Transfer);

with qw(App::Transfer::Role::Utils
        MooseX::Log::Log4perl);

use App::Transfer::Options;
use App::Transfer::Reader;
use App::Transfer::Writer;
use App::Transfer::Plugin;
use App::Transfer::RowTrafos;

option 'recipe_file' => (
    is            => 'ro',
    isa           => File,
    required      => 1,
    coerce        => 1,
    cmd_flag      => 'recipe',
    cmd_aliases   => [qw(r)],
    documentation => q[The recipe file.],
);

option 'input_file' => (
    is            => 'ro',
    isa           => File,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'in-file',
    cmd_aliases   => [qw(if)],
    documentation => q[The input file (xls | csv).],
);

option 'output_file' => (
    is            => 'ro',
    isa           => File,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'out-file',
    cmd_aliases   => [qw(of)],
    documentation => q[The output file (xls | csv).],
);

option 'input_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-target',
    cmd_aliases   => [qw(it)],
    documentation => q[The input database target name.],
);

option 'output_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-target',
    cmd_aliases   => [qw(ot)],
    documentation => q[The output database target name.],
);

option 'input_uri' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-uri',
    cmd_aliases   => [qw(iu)],
    documentation => q[The input database URI.],
);

option 'output_uri' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-uri',
    cmd_aliases   => [qw(ou)],
    documentation => q[The output database URI.],
);

has '_input_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            input_file    => $self->input_file,
            input_target  => $self->input_target,
            input_uri     => $self->input_uri,
        };
    },
);

has '_output_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            output_file   => $self->output_file,
            output_target => $self->output_target,
            output_uri    => $self->output_uri,
        };
    },
);

has 'reader_options' => (
    is      => 'ro',
    isa     => 'App::Transfer::Options',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Options->new(
            transfer => $self,
            options  => $self->_input_options,
            rw_type  => 'reader',
        );
    },
);

has 'writer_options' => (
    is      => 'ro',
    isa     => 'App::Transfer::Options',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Options->new(
            transfer => $self,
            options  => $self->_output_options,
            rw_type  => 'writer',
        );
    },
);

has 'reader' => (
    is       => 'ro',
    isa      => 'App::Transfer::Reader',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return App::Transfer::Reader->load({
            transfer => $self,
            recipe   => $self->recipe,
            reader   => $self->recipe->source->reader,
            options  => $self->reader_options,
        });
    },
);

has 'writer' => (
    is       => 'ro',
    isa      => 'App::Transfer::Writer',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return App::Transfer::Writer->load({
            transfer => $self,
            recipe   => $self->recipe,
            writer   => $self->recipe->destination->writer,
            options  => $self->writer_options,
        });
    },
);

has '_transform' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    reader  => 'transform',
    default => sub {
        return App::Transfer::Plugin->new;
    },
);

has '_contents' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->reader->get_data;
    },
);

has '_contents_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_contents',
);

sub execute {
    my $self = shift;

    hurl run => __x(
        "Unknown recipe syntax version: {version}",
        version => $self->recipe->header->syntaxversion
    ) if $self->recipe->header->syntaxversion != 1; # XXX ???

    $self->job_intro;

    my $io_type = $self->recipe->io_trafo_type;
    my $meth    = "transfer_$io_type";
    if ( $self->can($meth) ) {
        $self->$meth;    # execute the transfer
    }
    else {
        hurl run =>
            __x( "Wrong reader-writer combo: '{type}'!", type => $io_type );
    }
    $self->job_summary;
    return;
}

sub job_intro {
    my $self = shift;

    #-- Recipe

    my $recipe_l = __ 'Recipe:';
    my $recipe_v = $self->recipe->header->name;
    my @recipe_ldet
        = ( __ 'version:', __ 'syntax version:', __ 'description:' );
    my @recipe_vdet = (
        $self->recipe->header->version,
        $self->recipe->header->syntaxversion,
        $self->recipe->header->description,
    );
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    $recipe_l,                                                     $recipe_v;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@recipe_ldet,                                             \@recipe_vdet;

    return;
}

sub transfer_file2db {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    $self->job_info_file2db($engine->database);

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->reader_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->reader_options->file->stringify;

    hurl run => __x("The table '{table}' does not exists!",
        table => $table) unless $engine->table_exists($table);

    my $table_info = $engine->get_info($table);

    hurl run => __ 'No columns type info retrieved from database!'
        if keys %{$table_info} == 0;

    my @cols   = $self->sort_hash_by_pos($table_info);
    my $logfld = shift @cols;               # that the first column is

    my $iter = $self->_contents_iter;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        $row    = $self->do_transformations($row, $table_info, $logfld);
        $self->writer->insert($table, $row);

        #last;                                # DEBUG
    }

    return;
}

sub job_info_file2db {
    my ($self, $database) = @_;

    #-- Input

    my $input_l  = __ 'Input:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                  $input_l;

    my $worksheet = $self->reader->worksheet
        if $self->reader->can('worksheet');
    $worksheet //= 'not';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($self->reader_options->file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@i_l,                                                              \@i_v;

    #-- Output

    my $output_l = __ 'Output:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                 $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($self->recipe->destination->table, $database);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;

    return;
}

sub transfer_db2db {
    my $self = shift;

    my $src_table  = $self->recipe->source->table;
    my $dst_table  = $self->recipe->destination->table;
    my $src_engine = $self->reader->target->engine;
    my $dst_engine = $self->writer->target->engine;
    my $src_db     = $src_engine->database;
    my $dst_db     = $dst_engine->database;

    $self->job_info_db2db($src_db, $dst_db);

    hurl run => __x( "The source table '{table}' does not exists!",
        table => $src_table )
        unless $src_engine->table_exists($src_table);

    hurl run => __x( "The destination table '{table}' does not exists!",
        table => $dst_table )
        unless $dst_engine->table_exists($dst_table);

    # XXX Have to also check the host
    hurl run =>
        __( 'The source and the destination tables must be different!' )
        if ( $src_table eq $dst_table ) and ( $src_db eq $dst_db );

    my $table_info = $dst_engine->get_info($dst_table);
    hurl run => __( 'No columns type info retrieved from database!' )
        if keys %{$table_info} == 0;

    my @cols   = $self->sort_hash_by_pos($table_info);
    my $logfld = shift @cols;   # that the first column is

    my $iter = $self->_contents_iter;
    while ( $iter->has_next ) {
        my $row = $iter->next;
        $row    = $self->do_transformations($row, $table_info, $logfld);
        $self->writer->insert($dst_table, $row);

        #last;                   # DEBUG
    }

    return;
}

sub job_info_db2db {
    my ($self, $src_db, $dst_db) = @_;

    #-- Input

    my $input_l  = __ 'Input:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                  $input_l;
    my @i_l = (__ 'table:', __ 'database:');
    my @i_v = ($self->recipe->source->table, $src_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@i_l,                                                              \@i_v;

    #-- Output

    my $output_l = __ 'Output:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                 $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($self->recipe->destination->table, $dst_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;

    return;
}

sub job_summary {
    my $self = shift;

    #-- Summary

    my $summ_l = __ 'Summary:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                   $summ_l;
    my @o_l = (__ 'records inserted:', __ 'records skipped:');
    my @o_v = ( $self->writer->records_inserted,
                $self->writer->records_skipped );
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    \@o_l,                                                              \@o_v;
    print form
    " -----------------------------";
    return;
}

sub do_transformations {
    my ($self, $columns, $info, $logfld) = @_;

    #--  Logging settings

    $info->{logfld} = $logfld;
    $info->{logidx} = $columns->{$logfld} // '?';

    #--  Custom per field transformations from the recipe

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $field = $step->field;
        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field
        ) unless exists $info->{$field} and ref $info->{$field};
        my $p = $info->{$field};
        $p->{logfld} = $info->{logfld};
        $p->{logidx} = $info->{logidx};
        $p->{value}  = $columns->{$field};
        foreach my $meth ( @{ $step->method } ) {
            $p->{value} = $self->transform->do_transform( $meth, $p );
        }
        $columns->{$field} = $p->{value};
    }

    #--  Transformations per record (row)

    my $cmd = App::Transfer::RowTrafos->new(
        recipe    => $self->recipe,
        transform => $self->transform,
        engine    => $self->writer->target->engine,
        info      => $info,
    );

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $type = $step->type;
        if ( $type and $cmd->exists_in_type($type) ) {
            $columns = $cmd->get_type($type)->($self, $step, $columns);
        }
        else {
            hurl trafo_type =>
                __x( "Trafo type {type} not implemented", type => $type );
        }
    }

    #--  Transformations per field type

    while ( my ( $field, $value ) = each( %{$columns} ) ) {
        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field
        ) unless exists $info->{$field} and ref $info->{$field};
        my $p = $info->{$field};
        $p->{logfld} = $info->{logfld};
        $p->{logidx} = $info->{logidx};
        $p->{value}  = $value;    # add the value to p
        $p->{value}  = $self->transform->do_transform( $p->{type}, $p );
        $columns->{$field} = $p->{value};
    }

    return $columns;
}

__PACKAGE__->meta->make_immutable;

1;
