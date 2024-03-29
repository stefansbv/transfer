#
# Test the DBF writer
#
use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Writer::dbf';
    use_ok $CLASS or die;
}

my $output_path = 't/output';
my $output_file = 'fisacult.dbf';
my $output      = path $output_path, $output_file;

subtest 'Write DBF file' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $reader_opts_href = {};
    my $writer_opts_href = {
        output_file => $output_file,
        output_path => $output_path,
        debug       => 0,
    };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $reader_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $reader_opts_href,
        rw_type   => 'reader',
    ), 'reader options';
    ok my $header = $recipe->table->dst_header, 'get the recipe table header';
    my $writer_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $writer_opts_href,
        rw_type   => 'writer',
    );
    isa_ok $reader_options, 'App::Transfer::Options', 'reader options';
    isa_ok $writer_options, 'App::Transfer::Options', 'writer options';
    ok my $writer = App::Transfer::Writer->load({
        transfer => $transfer,
        header    => $header,
        writer   => 'dbf',
        reader_options => $reader_options,
        writer_options => $writer_options,
    }), 'new writer dbf object';
    is $writer->output_file, $output_file, 'dbf file name';
    is $writer->dbf_stru_file, path(qw{t output fisacult.str}),
        'dbf structure file';
    is ref $writer->dbf_stru_cols, 'ARRAY', 'the structure column names';
    is ref $writer->field_names, 'ARRAY', 'field names from the str file';
    is ref $writer->dbf_stru, 'ARRAY', 'dbf structure';
    is ref $writer->field_names, 'ARRAY', 'field names';
    is ref $writer->field_types, 'ARRAY', 'field types';
    is ref $writer->field_lengths, 'ARRAY', 'field lengths';
    is ref $writer->field_decimals, 'ARRAY', 'field decimals';

    lives_ok { $writer->dbf } 'create dbf instance and file';

    my $row = [1,1,695520,19249,0,396000,0,0,0,396000,0,0,0,0,0];
    lives_ok { $writer->insert( $row, 1 ) } 'insert row';
    $row = [3,1,8048160,197439,0,1943040,,0,0,1943040,0,0,0,0,0];
    lives_ok { $writer->insert( $row, 2 ) } 'insert row';
    is $writer->records_inserted, 2, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';
    lives_ok { $writer->finish } 'finish';
};

subtest 'Refuse to overwrite DBF' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $reader_opts_href = {};
    my $writer_opts_href = {
        output_file => 'siruta.dbf',
        output_path => 't',
        debug       => 0,
    };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $reader_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $reader_opts_href,
        rw_type   => 'reader',
    ), 'reader options';
    my $writer_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $writer_opts_href,
        rw_type   => 'writer',
    );
    isa_ok $reader_options, 'App::Transfer::Options', 'reader options';
    isa_ok $writer_options, 'App::Transfer::Options', 'writer options';
    ok my $header = $recipe->table->dst_header, 'get the recipe table header';
    ok my $writer = App::Transfer::Writer->load({
        transfer => $transfer,
        header   => $header,
        writer   => 'dbf',
        reader_options => $reader_options,
        writer_options => $writer_options,
    }), 'new writer dbf object';

    throws_ok { $writer->dbf }
        'App::Transfer::X',
        "Should have error for file exists and won't overwrite";
};

unlink $output or warn "unlink output $output: $!";

done_testing;
