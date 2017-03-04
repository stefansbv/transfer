use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::More;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Reader::xls';
    use_ok $CLASS or die;
}

ok my $recipe_file = path( 't', 'recipes', 'recipe-xls.conf' ), "Recipe file";
my $transfer = App::Transfer->new;
my $options_href = {
    input_file => 't/siruta.xls',
};
ok my $recipe = App::Transfer::Recipe->new(
    recipe_file => $recipe_file->stringify,
), 'new recipe instance';
my $options = App::Transfer::Options->new(
    transfer => $transfer,
    recipe   => $recipe,
    options  => $options_href,
    rw_type  => 'reader',
);
ok my $reader = App::Transfer::Reader->load({
    transfer => $transfer,
    recipe   => $recipe,
    reader   => 'xls',
    options  => $options,
}), 'new reader xls object';
is $reader->input_file, 't/siruta.xls', 'xls file name';
is $reader->dst_table, 'siruta', 'table name';
is $reader->worksheet, 'Foaie1', 'worksheet name';
is $reader->lastrow, 70, 'last row';
isa_ok $reader->workbook, 'Spreadsheet::ParseExcel::Workbook', 'workbook';

is $reader->maxrow, 0, 'initial maxrow value';
ok $reader->maxrow(1000), 'set maxrow value';
is $reader->maxrow, 1000, 'new maxrow value';

ok my @names = $reader->recipe->tables->all_table_names, 'get table name(s)';
my @tables = sort @names;
is_deeply \@tables, [qw{judete siruta}], 'sorted table name(s)';

my $hcols_s = [ qw{siruta denloc codp jud sirsup tip niv med fsj fsl rang} ];
my $hcols_j = [ qw{cod_jud denj fsj mnemonic zona} ];
my @expected_headers = (
  {
    header => $hcols_s,
    row    => 5,
    skip   => 0,
    table  => 'siruta',
  },
  {
    header => $hcols_j,
    row    => 28,
    skip   => 0,
    table  => "judete",
  },
);

ok my @headers = $reader->all_headers , 'get all headers';
is_deeply \@headers, \@expected_headers, 'header records';

is $reader->has_no_recordsets, 0 , 'has no recordsets is false (0)';
is $reader->num_recordsets, 2, 'number of record sets is 2';
my $recordset = { header => $hcols_s, min => 6, max => 27 };
is_deeply $reader->get_recordset('siruta'), $recordset, 'record set by name';

ok my $records = $reader->get_data, 'get data for table';
is scalar @{$records}, 18, 'got 18 records';

done_testing;
