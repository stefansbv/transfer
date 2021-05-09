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
    $CLASS = 'App::Transfer::Reader::excel';
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
     ok my @header = $recipe->table->src_header_raw,
      'get the recipe table header';
    my $tempfield = $recipe->table->tempfield;
    my $rectangle = $recipe->table->rectangle;
    ok my $reader = App::Transfer::Reader->load({
        transfer  => $transfer,
        header    => \@header,
        tempfield => $tempfield,
        rectangle => $rectangle,
        reader    => 'excel',
        options   => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/siruta.xls', 'xls file name';
    is $reader->worksheet, 1, 'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'A7', 'K21' ],
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
        fsl    => 321696512951,
    };

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
    ok my @header = $recipe->table->src_header_raw,
        'get the recipe table header';
    my $tempfield = $recipe->table->tempfield;
    my $rectangle = $recipe->table->rectangle;
    throws_ok {
        App::Transfer::Reader->load({
            transfer  => $transfer,
            header    => \@header,
            tempfield => $tempfield,
            rectangle => $rectangle,
            reader    => 'excel',
            options   => $options,
        });
    } 'App::Transfer::X',
        'Should get an exception for missing rectangle attrib';
    is $@->message, __("For the 'excel' reader, the table section must have a 'rectangle' attribute"),
        'The message should be from the translation';
};

subtest 'Read the SIRUTA table - skip fields' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls3.conf' ),
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
    ok my @header = $recipe->table->src_header_raw,
      'get the recipe table raw header';
    my $tempfield = $recipe->table->tempfield;
    my $rectangle = $recipe->table->rectangle;
    ok my $reader = App::Transfer::Reader->load({
        transfer  => $transfer,
        header    => \@header,
        tempfield => $tempfield,
        rectangle => $rectangle,
        reader    => 'excel',
        options   => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/siruta.xls', 'xls file name';
    is $reader->worksheet, 1, 'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'A7', 'J21' ],
        'siruta data rectangle';

    my $expecting_rec_15 = {
        siruta => 13515,
        denloc => "VALEA RUMÂNEŞTILOR",
        codp   => 115101,
        sirsup => 13490,
        rang   => "V",
    };

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
