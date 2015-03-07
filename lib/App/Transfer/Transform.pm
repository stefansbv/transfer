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
use namespace::autoclean;

use App::Transfer::Options;
use App::Transfer::Recipe;
use App::Transfer::Reader;
use App::Transfer::Writer;
use App::Transfer::Plugin;

with qw(App::Transfer::Role::Utils
        MooX::Log::Any);

has 'transfer' => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
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

has 'engine' => (
    is  => 'ro',
    isa => 'App::Transfer::Engine',
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

sub type_split {
    my ( $self, $step, $record, $logstr ) = @_;

    my %p;
    $p{logstr}    = $logstr;
    $p{name}      = $step->field_src;
    $p{value}     = $record->{ $step->field_src };
    $p{limit}     = $step->limit;
    $p{separator} = $step->separator;

    # Assuming that the number of values matches the number of destinations
    my @values = $self->plugin->do_transform( $step->method, %p );
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
        my $value = $record->{$field};
        push @{$values}, $value if defined $value;
    }
    my %p;
    $p{logstr}    = $logstr;
    $p{name}      = $step->field_dst;
    $p{separator} = $step->separator;
    $p{value}     = $values;
    $record->{ $step->field_dst }
        = $self->plugin->do_transform( $step->method, %p );

    return $record;
}

sub type_copy {
    my ( $self, $step, $record, $logstr ) = @_;

    my $field_src  = $step->field_src;
    my $field_dst  = $step->field_dst;
    my $attributes = $step->attributes;

    my %p;
    $p{logstr}     = $logstr;
    $p{value}      = $record->{$field_src};
    $p{field_src}  = $field_src;
    $p{field_dst}  = $field_dst;
    $p{attributes} = $attributes;
    $p{lookup_list}
        = $self->recipe->datasource->get_valid_list( $step->datasource );
    my $r = $self->plugin->do_transform( $step->method, %p );
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

    my %p;
    $p{logstr}     = $logstr;
    $p{value}      = $values;
    $p{field_src}  = $field_src;
    $p{field_dst}  = $field_dst;
    $p{attributes} = $attributes;
    my $r = $self->plugin->do_transform( $step->method, %p );
    foreach my $field ( keys %{$r} ) {
        $record->{$field} = $r->{$field};
    }

    return $record;
}

sub type_lookup {
    my ( $self, $step, $record, $logstr ) = @_;

    # Lookup value
    my $field_src  = $step->field_src;
    my $lookup_val = $record->{$field_src};

    return $record unless defined $lookup_val; # skip if undef

    my %p;
    $p{logstr}     = $logstr;
    $p{value}      = $lookup_val;
    $p{field_src}  = $field_src;
    $p{lookup_table} = $self->recipe->datasource->get_ds( $step->datasource );

    $record->{ $step->field_dst }
        = $self->plugin->do_transform( $step->method, %p );

    return $record;
}

sub type_lookupdb {
    my ( $self, $step, $record, $logstr ) = @_;

    # Lookup value
    my $lookup_val = $record->{ $step->field_src };
    return $record unless defined $lookup_val; # skip if undef

    # Hints
    if ( my $hint = $step->hints ) {
        my $hints = $self->recipe->datasource->get_hints($hint);
        if ( exists $hints->{$lookup_val} ) {
            $lookup_val = $hints->{$lookup_val};
        }
    }

    # Run-time parameters for the plugin
    my %p;
    $p{logstr} = $logstr;
    $p{table}  = $step->table;
    $p{engine} = $self->engine;
    $p{lookup} = $lookup_val;       # required, used only for loging
    $p{fields} = $step->fields;
    $p{where}  = { $step->where_fld => $lookup_val };

    my $result_aref = $self->plugin->do_transform( $step->method, %p );
    foreach my $field ( @{ $step->field_dst } ) {
        $record->{$field} = shift @{$result_aref};
    }

    return $record;
}

###

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

    my $table_info = $engine->get_info($table);
    hurl run => __ 'No columns type info retrieved from database!'
        if keys %{$table_info} == 0;

    $self->job_info_file2db($engine->database);

    $self->validate_destination;

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->reader_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->reader_options->file->stringify;

    hurl run => __x("The table '{table}' does not exists!",
        table => $table) unless $engine->table_exists($table);

    # Log field name
    my $logfld = $self->recipe->tables->get_table($table)->logfield;
    unless ($logfld) {
        my @cols = $self->sort_hash_by_pos($table_info);
        $logfld = shift @cols;  # that the first column is
    }

    my $iter = $self->_contents_iter; # call before record_count
    my $row_count    = 0;
    my $record_count = $self->reader->record_count;

    my $start_l  = __ 'Working:';
    my $record_l = __ 'records read:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                    $start_l;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    $record_l,                                      $record_count;

    return unless $record_count;

    my $progress = Progress::Any->get_indicator(
        target => $record_count,
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
    $worksheet //= 'n/a';
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

    $self->validate_destination;

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

    # Log field name  XXX logfield can be missing from config?
    my $tables = $self->recipe->tables;
    my $tableo = $tables->get_table($dst_table);
    my $logfld = $tableo->logfield;
    unless ($logfld) {
        my @cols = $self->sort_hash_by_pos($table_info);
        $logfld = shift @cols;              # that the first column is
    }

    my $iter = $self->_contents_iter; # call before record_count
    my $row_count    = 0;
    my $record_count = $self->reader->record_count;

    my $start_l  = __ 'Working:';
    my $record_l = __ 'records read:';
    print form
    " -----------------------------";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
                                    $start_l;
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    $record_l,                                      $record_count;

    return unless $record_count;

    my $progress = Progress::Any->get_indicator(
        target => $record_count,
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

sub transformations {
    my ($self, $record, $info, $logfld) = @_;

    #--  Logging settings

    my $logidx = exists $record->{$logfld} ? $record->{$logfld} : '?';
    my $logstr = qq{[$logfld=$logidx]};

    $record = $self->column_trafos( $record, $info, $logstr );
    $record = $self->record_trafos( $record, $info, $logstr );
    $record = $self->column_type_trafos( $record, $info, $logstr );

    return $record;
}

sub column_trafos {
    my ($self, $record, $info, $logstr) = @_;

    #--  Custom per field transformations from the recipe

    foreach my $step ( @{ $self->recipe->transform->column } ) {
        my $field = $step->field;
        # my $info  = $info->{$field};
        my %p;
        $p{logstr} = $logstr;
        $p{name}   = $field;
        $p{value}  = $record->{$field};
        foreach my $meth ( @{ $step->method } ) {
            $p{value} = $self->plugin->do_transform( $meth, %p );
        }
        $record->{$field} = $p{value};
    }
    return $record;
}

sub record_trafos {
    my ($self, $record, $info, $logstr) = @_;

    #--  Transformations per record (row)

    foreach my $step ( @{ $self->recipe->transform->row } ) {
        my $type = $step->type;
        my $p    = {};
        if ( $type and $self->trafo->exists_in_type($type) ) {
            $record = $self->trafo->get_type($type)
                ->( $self, $step, $record, $logstr );
        }
        else {
            hurl trafo_type =>
                __x( "Trafo type {type} not implemented", type => $type );
        }
    }
    return $record;
}

sub column_type_trafos {
    my ($self, $record, $info, $logstr) = @_;

    #--  Transformations per field type

    while ( my ( $field, $value ) = each( %{$record} ) ) {
        hurl field_info => __x(
            "Field info for '{field}' not found!  Header map config. <--> DB schema inconsistency",
            field => $field
        ) unless exists $info->{$field} and ref $info->{$field};
        my $meth = $info->{$field}{type};
        my %p    = %{ $info->{$field} };
        $p{logstr}        = $logstr;
        $p{value}         = $value;
        $p{value}         = $self->plugin->do_transform( $meth, %p );
        $record->{$field} = $p{value};
    }
    return $record;
}

sub validate_destination {
    my $self = shift;

    my $table  = $self->recipe->destination->table;
    my $engine = $self->writer->target->engine;

    my %fields_all;

    # Collect all destination field names and check if ...
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

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

=head1 Interface

=head2 Attributes

=head3 C<transfer>

=head3 C<recipe_file>

=head3 C<input_options>

=head3 C<output_options>

=head3 C<recipe>

=head3 C<reader_options>

=head3 C<writer_options>

=head3 C<reader>

=head3 C<writer>

=head3 C<plugin>

=head3 C<engine>

=head3 C<info>

=head3 C<_trafo_types>

=head3 C<_contents>

=head3 C<_contents_iter>

=head2 Instance Methods

=head3 C<type_split>

=head3 C<type_join>

=head3 C<type_copy>

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


=head3 C<type_batch>

=head3 C<type_lookup>

=head3 C<build_lookupdb>

=head3 C<type_lookupdb>

=head3 C<job_intro>

=head3 C<transfer_file2db>

=head3 C<job_info_file2db>

=head3 C<transfer_db2db>

=head3 C<job_info_db2db>

=head3 C<job_summary>

=head3 C<transformations>

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
