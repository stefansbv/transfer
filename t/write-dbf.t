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

my $output_file = 't/fisacult.dbf';

subtest 'DBF new' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { output_file => $output_file, };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'writer',
    );
    ok my $writer = App::Transfer::Writer->load(
        {   transfer => $transfer,
            recipe   => $recipe,
            writer   => 'dbf',
            options  => $options,
        } ), 'new writer dbf object';
    is $writer->output_file, $output_file, 'dbf file name';
    is $writer->dbf_stru_file, path('t', 'fisacult.str'), 'dbf structure file';
    is ref $writer->dbf_stru_cols, 'ARRAY', 'the structure column names';
    is ref $writer->field_names, 'ARRAY', 'field names from the str file';
    is ref $writer->dbf_stru, 'ARRAY', 'dbf structure';
    is ref $writer->field_names, 'ARRAY', 'field names';
    is ref $writer->field_types, 'ARRAY', 'field types';
    is ref $writer->field_lengths, 'ARRAY', 'field lengths';
    is ref $writer->field_decimals, 'ARRAY', 'field decimals';

    lives_ok { $writer->dbf } 'create dbf instance and file';

    my $row = [1,1,695520,19249,0,396000,0,0,0,396000,0,0,0,0,0];
    lives_ok {
        $writer->insert( 1, $row )
    } 'insert row';
    $row = [3,1,8048160,197439,0,1943040,,0,0,1943040,0,0,0,0,0];
    lives_ok {
        $writer->insert( 2, $row )
    } 'insert row';
    is $writer->records_inserted, 2, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';
};

subtest 'DBF exists' => sub {
    my $existing_file = 't/siruta.dbf';
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { output_file => $existing_file, };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'writer',
    );
    ok my $writer = App::Transfer::Writer->load(
        {   transfer => $transfer,
            recipe   => $recipe,
            writer   => 'dbf',
            options  => $options,
        } ), 'new writer dbf object';
    is $writer->output_file, $existing_file, 'dbf file name';
    throws_ok { $writer->dbf }
        'App::Transfer::X',
        'Should have error for file exists and wont overwrite';
};

unlink $output_file;

done_testing;
