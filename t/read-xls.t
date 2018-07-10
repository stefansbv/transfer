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
    $CLASS = 'App::Transfer::Reader::xls';
    use_ok $CLASS or die;
}

subtest 'Read the SIRUTA table' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls.conf' ),
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
        reader   => 'xls',
        options  => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/siruta.xls', 'xls file name';
    is $reader->worksheet,  'Foaie1',       'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $recipe->table->rectangle, [ 'A7', 'J21' ],
        'siruta data rectangle';

    my $expecting_rec_15 = {
        codp   => 115101,
        denloc => "VALEA RUMÂNEŞTILOR",
        fsj    => 3,
        jud    => 3,
        med    => 1,
        niv    => 3,
        rang   => "V",
        sirsup => 13490,
        siruta => 13515,
        tip    => 10,
    };

    ok my $aoh = $reader->_contents, 'get contents';
    cmp_deeply $aoh->[14], $expecting_rec_15, 'record 15 data looks good';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $count = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        if ($count == 15) {
            cmp_deeply $rec, $expecting_rec_15, 'record 15 data ok';
        }
        $count++;
    }

    is $reader->record_count, $count, 'counted records match record_count';
};

done_testing;

