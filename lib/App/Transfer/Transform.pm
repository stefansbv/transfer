package App::Transfer::Transform;

# ABSTRACT: Transformation methods

use 5.010001;
use utf8;
use Moose;
use MooseX::Iterator;
use MooseX::Types::Path::Tiny qw(Path File);
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use Perl6::Form;
use List::Compare;
use Progress::Any;
use Progress::Any::Output 'TermProgressBarColor';
use Lingua::Translit 0.23; # for "Common RON" table
use namespace::autoclean;

use App::Transfer::Options;
use App::Transfer::Recipe;
use App::Transfer::Reader;
use App::Transfer::Writer;
use App::Transfer::Plugin;

with qw(App::Transfer::Role::Utils
        MooX::Log::Any);

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        debug
        verbose
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
            recipe_file     => $self->recipe_file->stringify,
        );
    },
);

has 'tempfields' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    default  => sub {
        my $self   = shift;
        my $table = $self->recipe->destination->table;
        if ( my $recipe_table = $self->recipe->tables->get_table($table) ) {
            if ( $recipe_table->can('tempfield') ) {
                return $recipe_table->tempfield // [];
            }
        }
        return [];
    },
    handles  => {
        all_temp_fields => 'elements',
        find_temp_field => 'first',
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
        my $self = shift;
        return App::Transfer::Reader->load({
            transfer => $self->transfer,
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
            transfer => $self->transfer,
            recipe   => $self->recipe,
            writer   => $self->recipe->destination->writer,
            options  => $self->writer_options,
        });
    },
);

has 'plugin' => (
    is      => 'ro',
    isa     => 'App::Transfer::Plugin',
    lazy    => 1,
    default => sub {
        return App::Transfer::Plugin->new;
    },
);

has 'info' => (
    traits   => ['Hash'],
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    handles  => {
        get_info => 'get',
    },
);

has '_trafo_types' => (
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
        get_type       => 'get',
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

# Transliteration
has 'common_RON' => (
    is      => 'ro',
    isa     => 'Lingua::Translit',
    default => sub {
        return Lingua::Translit->new('Common RON');
    },
);

sub type_split {
    my ( $self, $step, $record, $logstr ) = @_;

    my $p;
    $p->{logstr}    = $logstr;
    $p->{name}      = $step->field_src;
    $p->{value}     = $record->{ $step->field_src };
    $p->{limit}     = $step->limit;
    $p->{separator} = $step->separator;

    # Assuming that the number of values matches the number of destinations
    my @values = $self->plugin->do_transform( $step->method, $p );
    my $i = 0;
    foreach my $value (@values) {
        my $field = ${ $step->field_dst }[$i];
        $record->{$field} = $value;
        $i++
    }

    return $record;
}

sub type_join {
    my ( $self, $step, $record, $logstr ) = @_;

    my $values;
    foreach my $field ( @{ $step->field_src } ) {
        if ( exists $record->{$field} ) {
            my $value = $record->{$field};
            push @{$values}, $value if defined $value;
        }
        else {
            $self->log->info(
                "$logstr: join: source field '$field' not found in record");
        }
    }
    my $p;
    $p->{logstr}    = $logstr;
    $p->{name}      = $step->field_dst;
    $p->{separator} = $step->separator;
    $p->{value}     = $values;

    $record->{ $step->field_dst }
        = $self->plugin->do_transform( $step->method, $p );

    return $record;
}

sub type_copy {
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $record->{$field_src};
    $p->{field_src}  = $field_src;
    $p->{field_dst}  = $field_dst;
    $p->{attributes} = $attributes;
    $p->{lookup_list}
        = $self->recipe->datasource->get_valid_list( $step->datasource );
    my $r = $self->plugin->do_transform( $step->method, $p );
    if ( ref $r ) {

        # Write to the destination field
        if ( $attributes->{APPEND} ) {
            if ( exists $r->{$field_dst} ) {
                my $old = $record->{$field_dst};
                my $dst = $old ? "$old, " : "";
                $record->{$field_dst} = $dst . $r->{$field_dst};
            }
        }
        elsif ( $attributes->{APPENDSRC} ) {
            if ( exists $r->{$field_dst} ) {
                my $old = $record->{$field_dst};
                my $dst = $old ? "$old, $field_src: " : "$field_src: ";
                $record->{$field_dst} = $dst . $r->{$field_dst};
            }
        }
        elsif ( $attributes->{REPLACE} ) {
            if ( exists $r->{$field_dst} ) {
                $record->{$field_dst} = $r->{$field_dst};
            }
        }
        elsif ( $attributes->{REPLACENULL} ) {
            if ( exists $r->{$field_dst} ) {
                $record->{$field_dst} = $r->{$field_dst}
                    if not defined $r->{$field_dst};
            }
        }

        # Delete source field value?
        if ( $attributes->{MOVE} ) {
            $record->{$field_src} = undef;
        }
    }

    return $record;
}

sub type_batch {
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my $values;
    foreach my $field ( @{$field_src} ) {
        unless ( exists $record->{$field} ) {
            hurl type_batch =>
                __x( "Error in recipe (batch): no such field '{field}'",
                field => $field );
        }
        push @{$values}, $record->{$field}
            if defined $record->{$field};
    }

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $values;
    $p->{field_src}  = $field_src;
    $p->{field_dst}  = $field_dst;
    $p->{attributes} = $attributes;
    my $r = $self->plugin->do_transform( $step->method, $p );
    foreach my $field ( keys %{$r} ) {
        $record->{$field} = $r->{$field};
    }

    return $record;
}

sub type_lookup {
    my ( $self, $step, $record, $logstr ) = @_;

	my $attribs = $step->attributes;

    # Lookup value
    my $field_src  = $step->field_src;
    my $lookup_val = $record->{$field_src};

    return $record unless defined $lookup_val; # skip if undef

	say "Looking for '$field_src'='$lookup_val'" if $self->debug;

    my $p;
    $p->{logstr}     = $logstr;
    $p->{value}      = $lookup_val;
    $p->{field_src}  = $field_src;
    $p->{lookup_table} = $self->recipe->datasource->get_ds( $step->datasource );
    if ( $step->valid_list ) {
        $p->{valid_list} = $self->recipe->datasource->get_valid_list(
            $step->valid_list
        );
    }
    $p->{attributes} = $attribs;

    $record->{ $step->field_dst }
        = $self->plugin->do_transform( $step->method, $p );

    return $record;
}

sub type_lookupdb {
    my ( $self, $step, $record, $logstr ) = @_;

    my $attribs = $step->attributes;

    # Lookup value and where field
    my $lookup_val = $record->{ $step->field_src };
    my $where_fld  = $step->where_fld;

    return $record unless defined $lookup_val; # skip if undef

    # Attributes - ignore diacritics
    if ( $attribs->{IGNOREDIACRITIC} ) {
        $lookup_val = $self->common_RON->translit($lookup_val);
    }

    # Hints
    if ( my $hint = $step->hints ) {
        if ( my $value = $self->recipe->datasource->hints->get_hint_for(
                $hint, $lookup_val ) ) {
            $lookup_val = $value;
        }
    }

    # Attributes - ignore case
    if ( $attribs->{IGNORECASE} ) {
        $where_fld  = "upper($where_fld)"; # all SQL engines have upper() ??? XXX
        $lookup_val = uc $lookup_val;
    }

    say "Looking for '$where_fld'='$lookup_val'" if $self->debug;

    # Run-time parameters for the plugin
    my $p;
    $p->{logstr} = $logstr;
    $p->{table}  = $step->table;
    $p->{engine}
        = $step->target eq 'destination'
        ? $self->writer->target->engine
        : $self->reader->target->engine;
    $p->{lookup} = $lookup_val;       # required, used only for loging
    $p->{fields} = $step->fields;
    $p->{where}  = { $where_fld => $lookup_val };
    $p->{attributes} = $attribs;

    my $fld_dst_map = $step->field_dst_map;
    my $result_aref = $self->plugin->do_transform( $step->method, $p );
    foreach my $dst_field ( @{ $step->field_dst } ) {
        my $field = $fld_dst_map->{$dst_field};
        $record->{$dst_field} = $result_aref->{$field};
    }

    return $record;
}

###

sub job_intro {
    my $self = shift;

    my $recipe_l = __ 'Recipe:';
    my $recipe_v = $self->recipe->header->name;
    my @recipe_ldet
        = ( __ 'version:', __ 'syntax version:', __ 'description:' );
    my @recipe_vdet = (
        $self->recipe->header->version,
        $self->recipe->header->syntaxversion,
        $self->recipe->header->description,
    );

    print form "-----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       $recipe_l,                                                         $recipe_v;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@recipe_ldet,               \@recipe_vdet;

    return;
}

sub job_info_input_file {
    my $self = shift;

    my $input_l  = __ 'Input:';
    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $input_l;

    my $worksheet = $self->reader->worksheet
        if $self->reader->can('worksheet');
    $worksheet //= 'n/a';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($self->reader_options->file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;

    return;
}

sub job_info_output_file {
    my $self = shift;

    my $output_l = __ 'Output:';
    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $output_l;

    my $worksheet = $self->writer->worksheet
        if $self->writer->can('worksheet');
    $worksheet //= 'n/a';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($self->writer_options->file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;

    return;
}

sub job_info_input_db {
    my ($self, $src_table, $src_db) = @_;

    my $input_l  = __ 'Input:';
    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $input_l;
    my @i_l = (__ 'table:', __ 'database:');
    my @i_v = ($src_table, $src_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;

    return;
}

sub job_info_output_db {
    my ($self, $dst_table, $dst_db) = @_;

    my $output_l = __ 'Output:';
    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($dst_table, $dst_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@o_l,                       \@o_v;

    return;
}

sub job_info_work {
    my ($self, $rec_count, $rows_read) = @_;
	$rec_count //= $rows_read;
    my $start_l   = __ 'Working:';
    my $record_rr = __ 'source rows read:';
    my $record_rc = __ 'records prepared:';
    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $start_l;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       $record_rr,                   $rows_read;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       $record_rc,                   $rec_count;
    return;
}

sub job_summary {
    my $self = shift;

    my $summ_l = __ 'Summary:';

    print form " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $summ_l;
    my @o_l = (__ 'records inserted:', __ 'records skipped:');
    my @o_v = ( $self->writer->records_inserted,
                $self->writer->records_skipped );
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@o_l,                       \@o_v;
    print form " -----------------------------";

    return;
}

###

sub job_transfer {
    my $self = shift;

    my $in_type  = $self->recipe->in_type;
    my $out_type = $self->recipe->out_type;

    # Change input/output type from CLI options
    $in_type  = 'file' if $self->input_options->{input_file};
    $out_type = 'file' if $self->output_options->{output_file};

    my $io_type = $self->io_trafo_type($in_type, $out_type);
    my $meth    = "transfer_$io_type";
    if ( $self->can($meth) ) {
        $self->$meth;                        # execute the transfer
    }
    else {
        hurl run => __x( "\nUnimplemented reader-writer combo: '{type}'!",
            type => $io_type );
    }
    return;
}

sub transfer_file2db {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    hurl run => __x( "The table '{table}' does not exists!", table => $table )
        unless $engine->table_exists($table);

    my $table_info = $engine->get_info($table);
    hurl run => __ 'No columns type info retrieved from database!'
        if keys %{$table_info} == 0;

    $self->job_info_input_file;
    $self->job_info_output_db($table, $engine->database);

    $self->validate_destination;

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->reader_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->reader_options->file->stringify;

    my $logfld = $self->get_logfiled_name($table, $table_info);

    my $iter      = $self->_contents_iter; # call before record_count
    my $row_count = 0;
    my $rows_read = $self->reader->rows_read;
    my $rec_count = $self->reader->record_count;

    $self->job_info_work($rec_count, $rows_read);

    return unless $rec_count;

    my $progress = Progress::Any->get_indicator(
        target => $rec_count,
    );
    while ( $iter->has_next ) {
        $row_count++;
        my $record = $iter->next;
        $record    = $self->transformations($record, $table_info, $logfld);
        $self->writer->insert($table, $record);
        $progress->update( message => "Record $row_count|" );

        #last;                                # DEBUG
    }
    $progress->finish;

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

    $self->job_info_input_db($src_table, $src_db);
    $self->job_info_output_db($dst_table, $dst_db);

    hurl run => __x( "The source table '{table}' does not exists!",
        table => $src_table )
        unless $src_engine->table_exists($src_table);
    hurl run => __x( "The destination table '{table}' does not exists!",
        table => $dst_table )
        unless $dst_engine->table_exists($dst_table);

    $self->validate_destination;

    # XXX Have to also check the host
    hurl run =>
        __( 'The source and the destination tables must be different!' )
        if ( $src_table eq $dst_table ) and ( $src_db eq $dst_db );

    my $table_info = $dst_engine->get_info($dst_table);
    hurl run => __( 'No columns type info retrieved from database!' )
        if keys %{$table_info} == 0;

    # Log field name  XXX logfield can be missing from config?
    my $tables = $self->recipe->tables;
    my $tableo = $tables->get_table($dst_table);
    my $logfld = $self->get_logfiled_name($dst_table, $table_info);

    my $iter         = $self->_contents_iter; # call before record_count
    my $row_count    = 0;
    my $rec_count = $self->reader->record_count;

    $self->job_info_work($rec_count);

    return unless $rec_count;

    my $progress = Progress::Any->get_indicator(
        target => $rec_count,
    );
    while ( $iter->has_next ) {
        $row_count++;
        my $record = $iter->next;
        $record    = $self->transformations($record, $table_info, $logfld);
        $self->writer->insert($dst_table, $record);
        $progress->update( message => "Record $row_count|" );

        #last;                   # DEBUG
    }
    $progress->finish;

    return;
}

sub transfer_db2file {
    my $self = shift;

    my $src_table  = $self->recipe->source->table;
    my $dst_table  = $self->recipe->destination->table;
    my $src_engine = $self->reader->target->engine;
    my $src_db     = $src_engine->database;

    $self->job_info_input_db($src_table, $src_db);
    $self->job_info_output_file;

    hurl run => __x( "The source table '{table}' does not exists!",
        table => $src_table )
        unless $src_engine->table_exists($src_table);

    my $src_table_info = $src_engine->get_info($src_table);
    my $dst_table_info = $self->recipe->tables->get_table($dst_table)->columns;

    hurl run => __( 'No columns type info retrieved from database!' )
        if keys %{$src_table_info} == 0;

    # Log field name  XXX logfield can be missing from config?
    my $logfld = $self->get_logfiled_name($src_table, $src_table_info);

    my $iter         = $self->_contents_iter; # call before record_count
    my $row_count    = 0;
    my $rec_count = $self->reader->record_count;

    $self->job_info_work($rec_count);

    return unless $rec_count;

    $self->writer->insert_header;

    my $progress = Progress::Any->get_indicator(
        target => $rec_count,
    );
    while ( $iter->has_next ) {
        $row_count++;
        my $record = $iter->next;
        $record    = $self->transformations($record, $dst_table_info, $logfld);
        $self->writer->insert(undef, $record);
        $progress->update( message => "Record $row_count|" );

        #last;                   # DEBUG
    }
    $progress->finish;

    return;
}

sub transfer_file2file {
    my $self = shift;

    my $dst_table = $self->recipe->destination->table;

    $self->job_info_input_file;
    $self->job_info_output_file;

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->reader_options->file;

    hurl run => __x("No output file specified; use '--of' or set the destination file in the recipe.") unless $self->writer_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->reader_options->file->stringify;

    my $logfld = $self->get_logfiled_name();

    my $iter         = $self->_contents_iter; # call before record_count
    my $row_count    = 0;
    my $rec_count = $self->reader->record_count;

    $self->job_info_work($rec_count);

    return unless $rec_count;

    my $dst_table_info = $self->recipe->tables->get_table($dst_table)->columns;

    $self->writer->insert_header;

    my $progress = Progress::Any->get_indicator(
        target => $rec_count,
    );
    while ( $iter->has_next ) {
        $row_count++;
        my $record = $iter->next;
        $record    = $self->transformations($record, $dst_table_info, $logfld);
        $self->writer->insert(undef, $record);
        $progress->update( message => "Record $row_count|" );

        #last;                                # DEBUG
    }
    $progress->finish;
    return;
}

sub transformations {
    my ($self, $record, $info, $logfld) = @_;

    #--  Logging settings
    my $logidx = $record->{$logfld} ? $record->{$logfld} : '?';
    my $logstr = $self->verbose ? qq{[$logfld=$logidx]} : qq{[$logidx]};

    $record = $self->column_trafos( $record, $info, $logstr );
    $record = $self->record_trafos( $record, $info, $logstr );
    $record = $self->column_type_trafos( $record, $info, $logstr );

    $self->remove_tempfields($record);

    return $record;
}

sub column_trafos {
    my ($self, $record, $info, $logstr) = @_;

    #--  Custom per field transformations from the recipe

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $field = $step->field;
        # my $info  = $info->{$field};
        my $p;
        $p->{logstr} = $logstr;
        $p->{name}   = $field;
        $p->{value}  = $record->{$field};
        foreach my $meth ( @{ $step->method } ) {
            $p->{value} = $self->plugin->do_transform( $meth, $p );
        }
        $record->{$field} = $p->{value};
    }
    return $record;
}

sub record_trafos {
    my ($self, $record, $info, $logstr) = @_;

    #--  Transformations per record (row)

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $type = $step->type;
        my $p    = {};
        if ( $type and $self->exists_in_type($type) ) {
            $record = $self->get_type($type)->( $self, $step, $record, $logstr );
        }
        else {
            hurl trafo_type =>
                __x( "Trafo type {type} not implemented", type => $type );
        }
    }
    return $record;
}

sub column_type_trafos {
    my ( $self, $record, $info, $logstr ) = @_;

    #--  Transformations per field type

    my $src_date_format = $self->recipe->source->date_format;
    my $src_date_sep    = $self->recipe->source->date_sep;

    while ( my ( $field, $value ) = each( %{$record} ) ) {
        next if $self->has_temp_field($field);

        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field
        ) unless exists $info->{$field} and ref $info->{$field};
        my $p    = $info->{$field};
        my $meth = $info->{$field}{type};
        if ( $meth eq 'date' ) {
            $p->{is_nullable} = $info->{$field}{is_nullable};
            $p->{src_format}  = $src_date_format;
            $p->{src_sep}     = $src_date_sep;
        }
        $p->{logstr}      = $logstr;
        $p->{value}       = $value;
        $p->{value}       = $self->plugin->do_transform( $meth, $p );
        $record->{$field} = $p->{value};
    }
    return $record;
}

sub validate_destination {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    my %fields_all;

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $dest = $step->field;
        $fields_all{$dest} = 1;
    }

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $dest = $step->field_dst;
        if (ref $dest eq 'ARRAY') {
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

    return unless scalar @trafo_fields; # no trafos no columns to check

    unless ( $engine->table_exists($table) ) {
        hurl table =>
            __x( 'Destination table "{table}" not found', table => $table );
    }
    my $table_fields = $engine->get_columns($table);
    my $lc = List::Compare->new('--unsorted', \@trafo_fields, $table_fields);
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

sub get_logfiled_name {
    my ( $self, $table, $table_info ) = @_;
    my $logfld;
    if ($table) {
        if ( my $recipe_table = $self->recipe->tables->get_table($table) ) {
            if ( $recipe_table->can('logfield') ) {
                return $recipe_table->logfield // '?';
            }
        }
        $logfld //= '?';
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

=head3 recipe_file

=head3 input_options

=head3 output_options

=head3 recipe

=head3 tempfields

=head3 reader_options

=head3 writer_options

=head3 reader

=head3 writer

=head3 plugin

=head3 info

=head3 _trafo_types

=head3 _contents

=head3 _contents_iter

=head2 INSTANCE METHODS

=head3 type_split

=head3 type_join

=head3 type_copy

A method best used to cleanup columns about to be normalized.  Using
the C<move_filtered> plug-in, the values not found in a data-source
valid list are moved to the destination column.  Attributes can be
used to alter the format of the destination value.

Example recipe (from the tests, subtest f.):

  <transform            row>
    <step>
      type                = copy
      datasource          = status
      field_src           = status
      method              = move_filtered
      field_dst           = observations
      attributes          = MOVE | APPENDSRC
    </step>
  </transform>

  <datasources>
    <valid_elts status>
      item                = Cancelled
      item                = Disputed
      item                = In Process
      item                = On Hold
      item                = Resolved
      item                = Shipped
    </valid_elts>
  </datasources>

Input records:

  my $records_4f = [
      { status => "Cancelled",      id => 1 },
      { status => "Disputed",       id => 2 },
      { status => "call the owner", id => 3 },
      { status => "On Hold",        id => 4 },
      { status => "tel 1234567890", id => 5, observations => 'some obs' },
      { status => "Shipped",        id => 6 },
  ];

Resulted records:

  my $expected_4f = [
      { id => 1, status => "Cancelled" },
      { id => 2, status => "Disputed" },
      { id => 3, observations => "status: call the owner", status => undef
      },
      { id => 4, status => "On Hold" },
      { id => 5, observations => "some obs, status: tel 1234567890", status => undef
      },
      { id => 6, status => "Shipped" },
  ];


=head3 type_batch

=head3 type_lookup

=head3 type_lookupdb

=head3 job_intro

=head3 job_info_input_file

=head3 job_info_output_file

=head3 job_info_input_db

=head3 job_info_output_db

=head3 job_info_work

Print info about the curent job.

=head3 job_summary

=head3 job_transfer

=head3 transfer_file2db

=head3 transfer_db2db

=head3 transfer_db2file

=head3 transfer_file2file

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

=head3 validate_destination

Collect all destination field names and check if the destination table
contains them, throw an exception if not.

=head3 remove_tempfields

Remove the temporary fields from the record.

=head3 has_temp_field

Return true if a field is in the tempfields list.

=head3 get_logfiled_name

Return the logfield value from the recipe configuration, or the first
column name from the database table.

=cut
