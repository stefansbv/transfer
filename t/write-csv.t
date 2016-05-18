#
# Test the CSV writer
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
    $CLASS = 'App::Transfer::Writer::csv';
    use_ok $CLASS or die;
}

subtest 'CSV OK' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { output_file => 't/output.csv', };
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
            writer   => 'csv',
            options  => $options,
        } ), 'new writer csv object';
    is $writer->output_file, 't/output.csv', 'csv file name';
    lives_ok { $writer->insert_header } 'insert header';
    lives_ok {
        $writer->insert( 'table', [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ] )
    } 'insert row';
    lives_ok { $writer->finish } 'finish';
    is $writer->records_inserted, 1, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';

};

done_testing;
