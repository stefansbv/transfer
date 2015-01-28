#
# Test the CSV reader
#
use 5.010;
use strict;
use warnings;
use utf8;

use Path::Class;
use Test::More;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Reader::csv';
    use_ok $CLASS or die;
}

ok my $recipe_file = file( 't', 'recipes', 'recipe-csv.conf' ), "Recipe file";
my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
);
my $options_href = {
    input_file => 't/siruta.csv',
};
my $options = App::Transfer::Options->new(
    transfer => $transfer,
    options  => $options_href,
    rw_type  => 'reader',
);
ok my $recipe = $transfer->recipe, 'has recipe';
ok my $reader = App::Transfer::Reader->load({
    transfer => $transfer,
    recipe   => $recipe,
    reader   => 'csv',
    options  => $options,
}), 'new reader csv object';
is $reader->input, 't/siruta.csv', 'csv file name';
ok my $records = $reader->get_data, 'get data for table';
is scalar @{$records}, 18, 'got 18 records';

done_testing;
