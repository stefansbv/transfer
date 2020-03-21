package App::Transfer::Transform;

# ABSTRACT: Transformation methods

use 5.010001;
use utf8;
use Moose;
use MooseX::Types::Path::Tiny qw(Path File);
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use Scalar::Util qw(blessed);
use List::Compare;
use Try::Tiny;
use File::Basename;

use Progress::Any '$progress';
use Progress::Any::Output;

# set Progress options
Progress::Any::Output->set(
    'TermProgressBarColor',
    width      => 80,
    fh         => \*STDERR,
    show_delay => 5,
);

use App::Transfer::Transform::Type;
use App::Transfer::Transform::Info;
use App::Transfer::Options;
use App::Transfer::Recipe;
use App::Transfer::Reader;
use App::Transfer::Writer;
use App::Transfer::Plugin;
use namespace::autoclean;

use Data::Dump qw/dump/;

with qw(App::Transfer::Role::Utils
        MooX::Log::Any);

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        debug
        verbose
        show_progress
    )],
);

has transform_types => (
    is       => 'ro',
    isa      => 'App::Transfer::Transform::Type',
    lazy     => 1,
    default => sub {
        my $self       = shift;
        my $trafo_type = App::Transfer::Transform::Type->new(
            recipe => $self->recipe,
            reader => $self->reader,
            writer => $self->writer,
        );
      },
    handles  => [qw(
        type_split
        type_join
        type_copy
        type_batch
        type_lookup
        type_lookupdb
    )],
);

has transform_info => (
    is       => 'ro',
    isa      => 'App::Transfer::Transform::Info',
    lazy     => 1,
    default  => sub {
        return App::Transfer::Transform::Info->new
    },
    handles  => [qw(
        job_intro
        job_info_input_file
        job_info_output_file
        job_info_input_db
        job_info_output_db
        job_info_prework
        job_info_postwork
        job_summary
    )],
);

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has 'input_options' => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'output_options' => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'recipe' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe->new(
            recipe_file => $self->recipe_file->stringify,
        );
    },
);

has 'tempfields' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default  => sub {
        my $self  = shift;
        my $table = $self->recipe->table;
        if ( $table->can('tempfield') ) {
            return $table->tempfield // [];
        }
        return [];
    },
    handles  => {
        all_temp_fields => 'elements',
        find_temp_field => 'first',
        has_temp_fields => 'count',
    },
);

has 'reader_options' => (
    is      => 'ro',
    isa     => 'App::Transfer::Options',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Options->new(
            transfer => $self->transfer,
            recipe   => $self->recipe,
            options  => $self->input_options,
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
            transfer => $self->transfer,
            recipe   => $self->recipe,
            options  => $self->output_options,
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
        my $self   = shift;
        my @header = $self->recipe->table->src_header_raw;
        push @header, $self->all_temp_fields if $self->has_temp_fields;
        return App::Transfer::Reader->load( {
            transfer       => $self->transfer,
            header         => \@header,
            table          => $self->recipe->source->table,
            rectangle      => $self->recipe->table->rectangle,
            allowemptyrows => $self->recipe->table->allowemptyrows,
            orderby        => $self->recipe->table->orderby,
            filter         => $self->recipe->table->filter,
            reader         => $self->recipe->source->reader,
            options        => $self->reader_options,
        } );
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
            transfer       => $self->transfer,
            header         => $self->recipe->table->dst_header,
            writer         => $self->recipe->destination->writer,
            reader_options => $self->reader_options,
            writer_options => $self->writer_options,
        });
    },
);

has 'plugin_column_type' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new( plugin_type => 'column_type' );
    },
);

has 'plugin_column' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new( plugin_type => 'column' );
    },
);

has 'plugin_row' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new( plugin_type => 'row' );
    },
);

has 'src_header' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->table->src_header;
    },
);

has 'dst_header' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->table->dst_header;
    },
);

has '_header_lc' => (
    is      => 'ro',
    isa     => 'List::Compare',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return List::Compare->new( $self->src_header, $self->dst_header );
    },
);

has 'has_common_headers' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( $self->recipe->has_field_list ) {
            return 1;
        }
        return $self->_header_lc->is_LequivalentR;
    },
);

has '_header_map' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->recipe->table->header_map;
    },
    handles => {
        field_pairs => 'kv',
    },
);

has '_columns_info' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $cols = $self->recipe->table->columns;
        return ref $cols ? $cols : {};
    },
    handles => {
        has_no_columns_info => 'is_empty',
        get_column_info     => 'get',
        set_column_info     => 'set',
        has_columns_info    => 'count',
        column_info_pairs   => 'kv',
    },
);

has 'ordered_dst_header' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $info = {};
        for my $pair ( $self->column_info_pairs ) {
            $info->{ $pair->[0] } = $pair->[1];
        }
        my @fields = $self->sort_hash_by_pos($info);
        return \@fields;
    },
    handles  => {
        all_ordered_fields => 'elements',
    },
);

has '_trafo_row_types' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {
            split     => \&type_split,
            join      => \&type_join,
            copy      => \&type_copy,
            batch     => \&type_batch,
            lookup    => \&type_lookup,
            lookupdb  => \&type_lookupdb,
        };
    },
    handles => {
        exists_in_type => 'exists',
        apply_trafo    => 'get',
    },
);

sub job_transfer {
    my $self = shift;

    $self->job_intro(
        name          => $self->recipe->header->name,
        version       => $self->recipe->header->version,
        syntaxversion => $self->recipe->header->syntaxversion,
        description   => $self->recipe->header->description,
    );

    my $src_type = $self->recipe->in_type;
    my $dst_type = $self->recipe->out_type;

    $self->validate_plugin_methods;

    my $meth_src = "validate_${src_type}_src";
    my $iter;
    if ( $self->can($meth_src) ) {
        $iter = $self->$meth_src;            # read the source
    }
    else {
        hurl run =>
            __x( "\nUnimplemented reader: '{type}'!", type => $src_type );
    }

    my $meth_dst = "validate_${dst_type}_dst";
    if ( $self->can($meth_dst) ) {
        $self->$meth_dst($iter);            # write to the destination
    }
    else {
        hurl run =>
            __x( "\nUnimplemented writer: '{type}'!", type => $dst_type );
    }

    $self->do_transfer;

    $self->job_summary(
        $self->writer->records_inserted,
        $self->writer->records_skipped,
    );

    return;
}

sub do_transfer {
    my ($self, $cols_info) = @_;

    $self->job_info_prework;

    my $logfld = $self->get_logfield_name();
    my $table  = $self->recipe->destination->table;

    my $iter = $self->reader->contents_iter;    # call before record_count
    my $row_count = 0;
    my $rec_count = $self->reader->record_count;

    hurl run => __("No input records!") unless $rec_count;

    # my $progress;
    if ( $self->show_progress ) {
        $progress = Progress::Any->get_indicator( target => $rec_count );
    }
    while ( $iter->has_next ) {
        $row_count++;
        my $record = $iter->next;
        $record = $self->map_fields_src_to_dst($record);
        $record = $self->transformations( $record, $cols_info, $logfld );
        $self->writer->insert( $record, $table );
        $progress->update( message => "Record $row_count|" )
            if $self->show_progress;

        #last;                                # DEBUG
    }

    $self->writer->finish if $self->writer->can('finish');

    $progress->finish if $self->show_progress;

    $self->job_info_postwork($rec_count);

    return;
}

sub validate_file_src {
    my $self = shift;
    my $input_file = try {
        $self->reader_options->file;
    }
    catch {
        say "ORIGINAL ERR: $_" if $self->debug;
        my $ident = $_->ident;
        if ( $ident eq 'options:invalid' ) {
            hurl run => __x(
                "Invalid input file specified; use '--if' or fix the source file in the recipe."
            );
        }
        elsif ( $ident eq 'options:missing' ) {
            hurl run => __x(
                "No input file specified; use '--if' or set the source file in the recipe."
            );
        }
        else {
            say "IDENT = $ident";
        }
    };
    my $worksheet
        = $self->reader->can('worksheet')
        ? $self->reader->worksheet
        : undef;
    $self->job_info_input_file($input_file, $worksheet);
    return;
}

sub validate_file_dst {
    my $self = shift;
    my $output_path = try {
        $self->writer_options->path;
    }
    catch {
        say "ORIGINAL ERR: $_" if $self->debug;
        my $ident = $_->ident;
        if ( $ident eq 'options:invalid' ) {
            hurl run => __x(
                "Invalid output path specified; fix the destination path in the recipe."
            );
        }
        else {
            say "IDENT=$ident";
        }
    };
    my $output_file = try {
        $self->writer_options->file;
    }
    catch {
        say "ORIGINAL ERR: $_" if $self->debug;
        my $ident = $_->ident;
        if ( $ident eq 'options:invalid' ) {
            hurl run => __x(
                "Invalid output file specified; use '--of' or fix the destination file in the recipe."
            );
        }
        elsif ( $ident eq 'options:missing' ) {
            hurl run => __x(
                "No output file specified; use '--of' or set the destination file in the recipe."
            );
        }
        else {
            say "IDENT=$ident";
        }
    };

    # Header, sorted if the 'columns' section is available
    if ( $self->has_no_columns_info ) {
        $self->writer->insert_header;
    }
    else {
        my @ordered = $self->all_ordered_fields;
        $self->writer->insert_header(\@ordered);
    }

    my $table_fields = $self->writer->header;

    my $worksheet
        = $self->writer->can('worksheet')
        ? $self->writer->worksheet
        : undef;
    $self->job_info_output_file($output_file, $worksheet);

    $self->validate_dst_file_fields;

    return;
}

sub validate_db_src {
    my $self = shift;

    my $target = $self->reader->target;

    my $src_engine = $self->reader->target->engine;
    my $database   = $src_engine->database;
    my $src_table  = $self->recipe->source->table;

    try {
        $src_engine->dbh;
    }
    catch {
        say "ORIGINAL ERR: $_" if $self->debug;
        my $ident = $_->ident;
        if ( $ident eq 'db:dbnotfound' ) {
            hurl run => __x(
                "Could not connect to the '{dbname}' database.",
                dbname => $database
            );
        }
        elsif ( $ident eq 'options:missing' ) {
            hurl run => __x(
                "Something id missing."
            );
        }
        else {
            say "IDENT = $ident";
        }
    };

    $src_engine->table_exists($src_table, 'or view');

    # - db exists
    # - table exists
    # - validate fields

    $self->job_info_input_db($src_table, $database);

    hurl run => __x( "The source table '{table}' does not exists!",
        table => $src_table )
        unless $src_engine->table_exists($src_table, 'or view');

    # XXX Have to also check the host
    # hurl run =>
    #     __( 'The source and the destination tables must be different!' )
    #     if ( $src_table eq $dst_table ) and ( $src_db eq $dst_db );

    return 1;
}

sub validate_db_dst {
    my ( $self, $iter ) = @_;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    if ( $self->has_columns_info ) {
        # for my $pair ( $self->column_info_pairs ) {
        #     say "field: $pair->[0]";
        # }
        # TODO: Should compare this to the real table info?
    }
    else {
        my $info = $engine->get_info($table);
        hurl run => __ 'No columns type info retrieved from database!'
            if keys %{$info} == 0;
        $self->set_column_info( %{$info} );
    }

    $self->job_info_output_db( $table, $engine->database );

    $self->validate_dst_db_fields;

    return;
}

sub map_fields_src_to_dst {
    my ( $self, $record ) = @_;
    my $new = {};
    for my $pair ( $self->field_pairs ) {
        $new->{ $pair->[1] } = $record->{ $pair->[0] };
    }

    # Add the tempfields with values
    foreach my $field ( $self->all_temp_fields ) {
        $new->{$field} = $record->{$field};
    }
    return $new;
}

sub transformations {
    my ($self, $record, $info, $logfld) = @_;

    #--  Logging settings
    my $logidx = $record->{$logfld} ? $record->{$logfld} : '?';
    my $logstr = $self->verbose ? qq{[$logfld=$logidx]} : qq{[$logidx]};

    $record = $self->column_trafos( $record, $logstr );
    $record = $self->record_trafos( $record, $logstr );
    $record = $self->column_type_trafos( $record, $logstr )
        if $self->has_columns_info;
    $self->remove_tempfields($record);
    return $record;
}

sub column_trafos {
    my ($self, $record, $logstr) = @_;

    #--  Custom per field transformations from the recipe

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $field = $step->field;
        my $type  = $step->type;
        my $p = {};
        $p->{logstr} = $logstr;
        $p->{name}   = $field;
        if ( $type eq 'default_value' ) {
            my $file_name = $self->reader_options->file;
            my ( $name, $path, $ext ) = fileparse( $file_name, qr/\.[^\.]*/ );
            print " extension: $ext\n";
            $p->{value} = $name;
        }
        else {
        $p->{value}  = $record->{$field};
        }
        foreach my $meth ( @{ $step->method } ) {
            $p->{value} = $self->plugin_column->do_transform( $meth, $p );
        }
        $record->{$field} = $p->{value};
    }
    return $record;
}

sub record_trafos {
    my ($self, $record, $logstr) = @_;

    #--  Transformations per record (row)

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $type = $step->type;
        my $p    = {};
        if ( $type and $self->exists_in_type($type) ) {
            $record = $self->apply_trafo($type)->( $self, $step, $record, $logstr );
        }
        else {
            hurl trafo_type =>
                __x( "Trafo type {type} not implemented", type => $type );
        }
    }
    return $record;
}

sub column_type_trafos {
    my ( $self, $record, $logstr ) = @_;

    #--  Transformations per field type

    my $src_date_format = $self->recipe->source->date_format;
    my $dst_date_format = $self->recipe->destination->date_format; # TODO: use it!
    my $src_date_sep    = $self->recipe->source->date_sep;

    while ( my ( $field, $value ) = each( %{$record} ) ) {
        # say "FIELD: $field";
        next if $self->has_temp_field($field);
        my $info = $self->get_column_info($field);
        next if $field eq '';                # skip skipped fields ;)
        hurl field_info => __x(
            "Field info for '{field}' not found! Header config. <--> DB schema inconsistency",
            field => $field
        ) unless $info and ref $info;
        my $p    = $info;
        my $meth = $info->{type};
        if ( $meth eq 'date' || $meth eq 'timestamp' ) {
            $p->{is_nullable} = $info->{is_nullable};
            $p->{src_format}  = $src_date_format;
            $p->{src_sep}     = $src_date_sep;
        }
        my $plug = $self->recipe->table->get_plugin($meth) // $meth;
        $p->{logstr} = $logstr;
        $p->{value}  = $value;
        $value = $self->plugin_column_type->do_transform( $plug, $p );
        $record->{$field} = $value;
    }
    return $record;
}

sub collect_recipe_fields {
    my $self = shift;
    my %fields_all;

    # Collect fields from column trafos
    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $dest = $step->field;
        $fields_all{$dest} = 1;
    }

    # Collect fields from row trafos
    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $dest = $step->field_dst;
        if ( ref $dest eq 'ARRAY' ) {
            my %fields = map { $_ => 1 } @{$dest};
            while ( my ( $key, $val ) = each %fields ) {
                $fields_all{$key} = $val;
            }
        }
        else {
            $fields_all{$dest} = 1;
        }
    }
    my @trafo_fields = sort keys %fields_all;
    return \@trafo_fields;
}

sub collect_recipe_methods {
    my $self = shift;
    my %methods_all;
    $methods_all{column} = {};
    $methods_all{row}    = {};

    # Collect methods from column trafos
    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $meth = $step->method;
        if ( ref $meth eq 'ARRAY' ) {
            my %methods = map { $_ => 0 } @{$meth};
            while ( my ( $key, $val ) = each %methods ) {
                $methods_all{column}{$key} = $val;
            }
        }
        else {
            $methods_all{column}{$meth} = 0;
        }
    }

    # Collect methods from row trafos
    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $meth = $step->method;
        $methods_all{row}{$meth} = 0;
    }

    return \%methods_all;
}

sub validate_dst_file_fields {
    my $self = shift;

    my $table_fields = $self->recipe->table->dst_header;
    my $trafo_fields = $self->collect_recipe_fields;

    return unless scalar @{$trafo_fields}; # no trafos no columns to check

    my $lc = List::Compare->new('--unsorted', $trafo_fields, $table_fields);
    my @error = $lc->get_Lonly;              # not in the table

    hurl field_info => __x(
        'Destination fields from trafos not found in the destination table: "{list}"',
        list  => join( ', ', @error ),
    ) unless scalar @error == 0;

    return;
}

sub validate_plugin_methods {
    my $self = shift;
    my $mets = $self->get_plugin_methods;
    my @missing;
    foreach my $rc ( keys %{$mets} ) {
        while ( my ( $k, $v ) = each( %{ $mets->{$rc} } ) ) {
            push @missing, "$rc: $k" if $v == 0;
        }
    }
    hurl plugins => __x(
        'Missing plugins: "{list}"',
        list  => join( ', ', @missing ),
    ) if scalar @missing > 0;
    return;
}

sub get_plugin_methods {
    my $self  = shift;
    my $meths = $self->collect_recipe_methods;
    foreach my $method ( keys %{ $meths->{column} } ) {
      PLUGIN:
        for my $plugin ( @{ $self->plugin_column->plugins } ) {
            if ( $plugin->can($method) ) {
                $meths->{column}{$method} = 1;
                last PLUGIN;
            }
        }
    }
    foreach my $method ( keys %{ $meths->{row} } ) {
      PLUGIN:
        for my $plugin ( @{ $self->plugin_row->plugins } ) {
            if ( $plugin->can($method) ) {
                $meths->{row}{$method} = 1;
                last PLUGIN;
            }
        }
    }
    return $meths;
}

sub validate_dst_db_fields {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    my $trafo_fields = $self->collect_recipe_fields;

    return unless scalar @{$trafo_fields}; # no trafos no columns to check

    unless ( $engine->table_exists($table, 'or view') ) {
        hurl table =>
            __x( 'Destination table "{table}" not found', table => $table );
    }
    my $table_fields = $engine->get_columns($table);
    my $lc = List::Compare->new('--unsorted', $trafo_fields, $table_fields);
    my @error = $lc->get_Lonly;              # not in the table

    hurl field_info => __x(
        'Destination fields from trafos not found in the "{table}" destination table: "{list}"',
        table => $table,
        list  => join( ', ', @error ),
    ) unless scalar @error == 0;

    return;
}

sub remove_tempfields {
    my ($self, $record) = @_;
    foreach my $field ( $self->all_temp_fields ) {
        delete $record->{$field};
    }
    return $record;
}

sub has_temp_field {
    my ($self, $field) = @_;
    return $self->find_temp_field( sub { $_ eq $field } );
    return;
}

sub get_logfield_name {
    my ( $self, $table_info ) = @_;
    my $logfld;
    if ( $self->recipe->table->can('logfield') ) {
        return $self->recipe->table->logfield // '?';
    }
    if ( !$logfld and $table_info ) {
        my @cols = $self->sort_hash_by_pos($table_info);
        $logfld = shift @cols;    # this the first column is
    }
    $logfld //= '?';
    return $logfld;
}

1;

__END__

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 transfer

=head3 transform_types

=head3 transform_info

=head3 recipe_file

=head3 input_options

=head3 output_options

=head3 recipe

=head3 tempfields

An attribute holding the temporary fields defined in the recipe.  The
values are added to the current record and than removed befor sending
the record to the writer.

This fields exists in the source table but not in the destination
table and their contents is transfered to another destination field
using, for example, the C<copy> transformation with the APPENDSRC
attribute, or the C<split> transformation.

=head3 reader_options

=head3 writer_options

=head3 reader

=head3 writer

=head3 plugin_column_type

=head3 plugin_column

=head3 src_header

=head3 dst_header

=head3 _header_lc

Build and return a L<List::Compare> instance from the source and
destination header arrays.

=head3 has_common_headers

Returns true if the source and destination headers are equivalent.  No
need to compare if the recipe has a field list.

=head3 _header_map

A hash holding the mapping between the source and destination field
names.

=head3 _columns_info

=head3 ordered_dst_header

=head3 _trafo_row_types

=head2 METHODS

=head3 job_transfer

The dispatch method for the different input - output combinations for
the transformations to be executed.

=head3 do_transfer

=head3 validate_file_src

=head3 validate_file_dst

=head3 validate_db_src

=head3 validate_db_dst

=head3 map_fields_src_to_dst

=head3 transformations

Apply the three transformations to a record in order.

=over

=item 1. column_trafos

=item 2. record_trafos

=item 3. column_type_trafos

See below a description of each transformation type.

=back

=head3 column_trafos

Custom per field transformations.  This type of transformation works
on a field at a time.  Each transformation step defined in the
C<transform/column> section of the recipe is applied to the C<field>
data.  More than one method can be applied in the order of
declaration.

Example:

  <transform            column>
    <step>
      field               = codp
      method              = number_only
      method              = null_ifzero
    </step>
  </transform>

This is the first type of transformation to be applied.

=head3 record_trafos

Transformations per record (row).  This type of transformation works
on the entire current record of data.  It can be used to split a field
data into two or more fields, or to join, copy or move data between
fields.

This is the second type of transformation to be applied.

=head3 column_type_trafos

Transformations per field type are used to validate the data for the
destination type of the column.  If the data is not a valid type or
overflows than a log entry is added.

=head3 collect_recipe_fields

Collect all recipe field names from the row and column transformations
and return them as an sorted array reference.

=head3 collect_recipe_methods

Collect all recipe method names from the row and column
transformations and return them as a HoH with two keys: C<column> and
C<row>.

For example:

    {
        row => {
            lookup_in_dbtable   => 0,
            move_filtered       => 0,
            split_field         => 0,
        },
        column => {
            null_ifzero => 0,
        },
    };

=head3 validate_dst_file_fields

=head3 validate_plugin_methods

Throw an exception with the list of missing plugins if any.

=head3 get_plugin_methods

Update the data structure returned by the L<collect_recipe_methods>,
by setting the value to 1 for the method names that exists in the
plugins list.

=head3 validate_dst_db_fields

Chack if recipe field from the row and column transformations are in
the destination table, throw an exception if not.

=head3 remove_tempfields

Remove the temporary fields from the record.

=head3 has_temp_field

Return true if a field is in the tempfields list.

=head3 get_logfield_name

Return the logfield value from the recipe configuration, or the first
column name from the database table.

=cut
