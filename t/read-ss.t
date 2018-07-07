use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most;

use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

use Data::Dump;
my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Reader::spreadsheet';
    use_ok $CLASS or die;
}

subtest 'Read the SIRUTA table' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-ss-siruta.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/siruta.xls', verbose => 1, };
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
        reader   => 'spreadsheet',
        options  => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/siruta.xls', 'xls file name';
    is $reader->worksheet,  'Foaie1',       'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    ok my @names = $reader->recipe->tables->all_table_names,
        'get table name(s)';
    my @tables = sort @names;
    cmp_deeply \@tables, [qw{judete siruta}], 'sorted table name(s)';

    ok my $siruta_table = $recipe->tables->get_table('siruta'), 'siruta table.';
    cmp_deeply $siruta_table->rectangle, ['A7','C21'], 'siruta data rectangle';

    ok my $aoh = $reader->_contents, 'get contents';
    use Data::Dump; dd $aoh;
};

# subtest 'Read the Judete table' => sub {
#     ok my $recipe_file = path( 't', 'recipes', 'recipe-xls-judete.conf' ),
#         "Recipe file";
#     my $transfer = App::Transfer->new;
#     my $options_href = { input_file => 't/siruta.xls', };
#     ok my $recipe
#         = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
#         ), 'new recipe instance';
#     my $options = App::Transfer::Options->new(
#         transfer => $transfer,
#         recipe   => $recipe,
#         options  => $options_href,
#         rw_type  => 'reader',
#     );
#     ok my $reader = App::Transfer::Reader->load(
#         {   transfer => $transfer,
#             recipe   => $recipe,
#             reader   => 'xls',
#             options  => $options,
#         }
#         ),
#         'new reader xls object';
#     is $reader->input_file, 't/siruta.xls', 'xls file name';
#     is $reader->dst_table,  'judete',       'table name';
#     is $reader->worksheet,  'Foaie1',       'worksheet name';
#     is $reader->lastrow,    71,             'last row';
#     isa_ok $reader->workbook, 'Spreadsheet::ParseExcel::Workbook', 'workbook';

#     is $reader->maxrow, 71, 'initial maxrow value';

#     ok my @names = $reader->recipe->tables->all_table_names,
#         'get table name(s)';
#     my @tables = sort @names;
#     cmp_deeply \@tables, [qw{judete siruta}], 'sorted table name(s)';

#     my $hcols_s
#         = [qw{siruta denloc codp jud sirsup tip niv med fsj rang fsl}];
#     my $hcols_j          = [qw{cod_jud denj fsj mnemonic zona}];
#     my @expected_headers = (
#         {   header => $hcols_s,
#             row    => 6,
#             skip   => 0,
#             table  => 'siruta',
#         },
#         {   header => $hcols_j,
#             row    => 29,
#             skip   => 0,
#             table  => "judete",
#         },
#     );

#     my @expected_names = (qw{
# 	  ALBA
# 	  ARAD
# 	  ARGES
# 	  BACAU
# 	  BIHOR
# 	  BISTRITA-NASAUD
# 	  BOTOSANI
# 	  BRASOV
# 	  BRAILA
# 	  BUZAU
#     });
#     ok my @headers = $reader->all_headers, 'get all headers';
#     cmp_deeply \@headers, \@expected_headers, 'header records';

#     is $reader->has_no_recordsets, 0, 'has no recordsets is false (0)';
#     is $reader->num_recordsets,    2, 'number of record sets is 2';
#     my $recordset = { header => $hcols_j, min => 30, max => 71 };
#     cmp_deeply $reader->get_recordset('judete'), $recordset,
#         'record set by name';

#     ok my $records = $reader->get_data, 'get data for table';
#     is scalar @{$records}, 42, 'got 42 records';
# 	my @got_names = map { $_->{denj} } @{$records};
# 	cmp_deeply \@got_names, \@expected_names, 'judete names';
# };

done_testing;
