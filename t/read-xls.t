use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most;

use Locale::TextDomain 1.20 qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

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

    cmp_deeply $reader->rectangle, [ 'A7', 'J21' ],
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

subtest 'Missing rectangle attribute' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls2.conf' ),
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
    is $reader->worksheet,  1, 'worksheet number';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    throws_ok { $reader->rectangle } 'App::Transfer::X',
        'Should get an exception for missing rectangle attrib';
    is $@->message, __("For the 'xls' reader, the table section must have a 'rectangle' attribute"),
        'The message should be from the translation';

    throws_ok { $reader->header } 'App::Transfer::X',
        'Should get an exception for wrong header attrib';
    is $@->message, __("For the 'xls' reader, the table header must have field attributes"),
        'The message should be from the translation';
};

done_testing;

