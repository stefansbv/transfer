package App::Transfer::Command::info;

# ABSTRACT: Command to print info about recipes

use 5.010001;
use utf8;
use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use Moose::Util::TypeConstraints;
use Path::Tiny qw[cwd path];
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use App::Transfer::Transform;
use namespace::autoclean;

extends qw(App::Transfer);

with qw(App::Transfer::Role::Utils);

parameter 'recipe' => (
    is            => 'ro',
    isa           => Path,
    required      => 0,
    coerce        => 1,
    documentation => q[The recipe file.],
);

###

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->recipe || hurl "Recipe file required";
    },
);

has 'trafo' => (
    is      => 'ro',
    isa     => 'App::Transfer::Transform',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Transform->new(
            transfer       => $self,
            input_options  => {},
            output_options => {},
            recipe_file    => $self->recipe,
        );
    },
);

sub execute {
    my $self = shift;
    $self->job_info;    
    return;
}

sub job_info {
    my $self = shift;

    $self->trafo->job_intro;
    
    my $in_type  = $self->trafo->recipe->in_type;
    my $out_type = $self->trafo->recipe->out_type;

    my $io_type = $self->trafo->io_trafo_type($in_type, $out_type);
    my $meth    = "transfer_$io_type";
    if ( $self->can($meth) ) {
        $self->$meth;                        # execute the transfer
    }
    else {
        hurl run => __x( "\nUnimplemented reader-writer combo: '{type}'!",
            type => $io_type );
    }

    $self->job_close;
    
    return;
}

sub job_close {
    print " -----------------------------\n";
}

sub transfer_file2db {
    my $self = shift;

    my $table  = $self->trafo->recipe->destination->table;
    my $engine = $self->trafo->writer->target->engine;

    hurl run => __x( "The table '{table}' does not exists or is not readable!", table => $table )
        unless $engine->table_exists($table);

    my $table_info = $engine->get_info($table);
    hurl run => __ 'No columns type info retrieved from database!'
        if keys %{$table_info} == 0;

    $self->trafo->job_info_input_file;
    $self->trafo->job_info_output_db($table, $engine->database);
}

sub transfer_db2db {
    my $self = shift;

    my $src_table  = $self->trafo->recipe->source->table;
    my $dst_table  = $self->trafo->recipe->destination->table;
    my $src_engine = $self->trafo->reader->target->engine;
    my $dst_engine = $self->trafo->writer->target->engine;
    my $src_db     = $src_engine->database;
    my $dst_db     = $dst_engine->database;

    $self->trafo->job_info_input_db($src_table, $src_db);
    $self->trafo->job_info_output_db($dst_table, $dst_db);

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

    my $logfld = $self->trafo->get_logfield_name($table_info);

    return;
}

sub transfer_db2file {
    my $self = shift;

    my $src_table  = $self->trafo->recipe->source->table;
    my $dst_table  = $self->trafo->recipe->destination->table;
    my $src_engine = $self->trafo->reader->target->engine;
    my $src_db     = $src_engine->database;

    $self->trafo->job_info_input_db($src_table, $src_db);
    $self->trafo->job_info_output_file;

    # hurl run => __x( "The source table '{table}' does not exists!",
    #     table => $src_table )
    #     unless $src_engine->table_exists($src_table);

    # my $src_table_info = $src_engine->get_info($src_table);
    my $dst_table_info = $self->trafo->recipe->table->columns;
    my @fields = $self->sort_hash_by_pos($dst_table_info);
    
    # hurl run => __( 'No columns type info retrieved from database!' )
    #     if keys %{$src_table_info} == 0;

    # my $logfld = $self->trafo->get_logfield_name($src_table_info);

    return;
}

sub transfer_file2file {
    my $self = shift;

    my $dst_table = $self->trafo->recipe->destination->table;

    $self->trafo->job_info_input_file;
    $self->trafo->job_info_output_file;

    hurl run => __x("No input file specified; use '--if' or set the source file in the recipe.") unless $self->trafo->reader_options->file;

    hurl run => __x("No output file specified; use '--of' or set the destination file in the recipe.") unless $self->trafo->writer_options->file;

    hurl run => __x("Invalid input file specified; use '--if' or fix the source file in the recipe.") unless -f $self->trafo->reader_options->file->stringify;

    my $logfld = $self->trafo->get_logfield_name();

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Command to generate recipes

=head1 Description

The C<new> command.

=head1 Interface

=head2 Attributes

=head3 execute

=cut
