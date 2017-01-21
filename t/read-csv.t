#
# Test the CSV reader
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
    $CLASS = 'App::Transfer::Reader::csv';
    use_ok $CLASS or die;
}

subtest 'CSV OK' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/siruta.csv', };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'reader',
    );
    ok my $reader = App::Transfer::Reader->load(
        {   transfer => $transfer,
            recipe   => $recipe,
            reader   => 'csv',
            options  => $options,
        } ), 'new reader csv object';
    is $reader->input_file, 't/siruta.csv', 'csv file name';
    ok my $records = $reader->get_data, 'get data for table';
    is scalar @{$records}, 18, 'got 18 records';
};

subtest 'CSV with lc header' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/siruta-lower.csv', };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'reader',
    );
    ok my $reader = App::Transfer::Reader->load(
        {   transfer => $transfer,
            recipe   => $recipe,
            reader   => 'csv',
            options  => $options,
        } ), 'new reader csv object';
    is $reader->input_file, 't/siruta-lower.csv', 'csv file name';
    throws_ok { $reader->get_data }
        qr/\QHeader map <--> CSV file header inconsistency/,
        'Should get an exception for header map - file header inconsistency';
};

done_testing;
