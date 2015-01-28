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
    $CLASS = 'App::Transfer::Reader::excel';
    use_ok $CLASS or die;
}

ok my $recipe_file = file( 't', 'recipes', 'recipe-xls.conf' ), "Recipe file";
my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
);
my $options_href = {
    input_file => 't/siruta.xls',
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
    reader   => 'excel',
    options  => $options,
}), 'new reader excel object';
is $reader->input, 't/siruta.xls', 'excel file name';
is $reader->table, 'siruta', 'table name';
is $reader->worksheet, 'Foaie1', 'worksheet name';
isa_ok $reader->workbook, 'Spreadsheet::ParseExcel::Workbook', 'workbook';

is $reader->maxrow, 0, 'initial maxrow value';
ok $reader->maxrow(1000), 'set maxrow value';
is $reader->maxrow, 1000, 'new maxrow value';

ok my @table_names = $reader->recipe->tables->all_table_names, 'get table name(s)';
is_deeply \@table_names, [qw{judete siruta}], 'sorted table name(s)';

ok my @headers = $reader->all_headers , 'get all headers';
foreach my $header ( $reader->all_headers ) {
    my $table = $header->{table};
    my $hrow  = $header->{row};
    my $skip  = $header->{skip} // 0;
}

my $header = [ qw{siruta denloc codp jud sirsup tip niv med fsj fsl rang} ];
# my $head = {
#     header => $header,
#     row    => 0, skip  => 0, table => "siruta",
# };
# is_deeply \@headers, [$head], 'header records';
# is_deeply $reader->get_header(0), $head, 'header record 0';

is $reader->has_no_recordsets, 0 , 'has no recordsets is false (0)';
is $reader->num_recordsets, 2, 'number of record sets is 2';
my $recordset = { header => $header, min => 6, max => 27 };
is_deeply $reader->get_recordset('siruta'), $recordset, 'record set by name';

ok my $records = $reader->get_data, 'get data for table';
is scalar @{$records}, 18, 'got 18 records';

done_testing;
