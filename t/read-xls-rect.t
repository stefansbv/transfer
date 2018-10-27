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

my $expected = [
    {
        col_a => 'A1',
        col_b => 'B1',
        col_c => 'C1',
        col_d => 'D1',
        col_e => 'E1',
        col_f => 'F1',
    },
    {
        col_a => 'A2',
        col_b => 'B2',
        col_c => 'C2',
        col_d => 'D2',
        col_e => 'E2',
        col_f => 'F2',
    },
    {
        col_a => 'A3',
        col_b => 'B3',
        col_c => 'C3',
        col_d => 'D3',
        col_e => 'E3',
        col_f => 'F3',
    },
    {
        col_a => 'A4',
        col_b => 'B4',
        col_c => 'C4',
        col_d => 'D4',
        col_e => 'E4',
        col_f => 'F4',
    },
    {
        col_a => 'A5',
        col_b => 'B5',
        col_c => 'C5',
        col_d => 'D5',
        col_e => 'E5',
        col_f => 'F5',
    },
];

my $expected_2 = [
    {
        col_b => 'B1',
        col_c => 'C1',
        col_d => 'D1',
        col_e => 'E1',
    },
    {
        col_b => 'B2',
        col_c => 'C2',
        col_d => 'D2',
        col_e => 'E2',
    },
    {
        col_b => 'B3',
        col_c => 'C3',
        col_d => 'D3',
        col_e => 'E3',
    },
    {
        col_b => 'B4',
        col_c => 'C4',
        col_d => 'D4',
        col_e => 'E4',
    },
    {
        col_b => 'B5',
        col_c => 'C5',
        col_d => 'D5',
        col_e => 'E5',
    },
];

my $expected_3 = [
    {
        col_a => 'A1',
        col_c => 'C1',
        col_f => 'F1',
    },
    {
        col_a => 'A2',
        col_c => 'C2',
        col_f => 'F2',
    },
    {
        col_a => 'A3',
        col_c => 'C3',
        col_f => 'F3',
    },
    {
        col_a => 'A4',
        col_c => 'C4',
        col_f => 'F4',
    },
    {
        col_a => 'A5',
        col_c => 'C5',
        col_f => 'F5',
    },
];

subtest 'Full range' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls-rect.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new( debug => 0 );
    my $options_href = { input_file => 't/rectangle.xls',  };
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
        reader    => 'xls',
        options   => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/rectangle.xls', 'xls file name';
    is $reader->worksheet, 1, 'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'A5', 'F9' ],
        'siruta data rectangle';
    cmp_deeply $reader->rect_o, [1,5],'rext min col, min row';
    cmp_deeply $reader->rect_v, [6,9],'rext max col, max row';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $i = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        cmp_deeply $rec, $expected->[$i], "record $i data ok";
        $i++;
    }
    is $i, 5, 'compared all records';
    is $reader->record_count, $i, 'counted records match record_count';
};

subtest 'Partial range - no skip' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls-rect-2.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new( debug => 0 );
    my $options_href = { input_file => 't/rectangle.xls',  };
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
        reader    => 'xls',
        options   => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/rectangle.xls', 'xls file name';
    is $reader->worksheet, 1, 'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'B5', 'E9' ],
        'siruta data rectangle';
    cmp_deeply $reader->rect_o, [2,5],'rext min col, min row';
    cmp_deeply $reader->rect_v, [5,9],'rext max col, max row';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $i = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        cmp_deeply $rec, $expected_2->[$i], "record $i data ok";
        $i++;
    }
    is $i, 5, 'compared all records';
    is $reader->record_count, $i, 'counted records match record_count';
};

subtest 'Full range - skip some inner fields' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls-rect-3.conf' ),
      "Recipe file";
    my $transfer = App::Transfer->new( debug => 0 );
    my $options_href = { input_file => 't/rectangle.xls', };
    ok my $recipe =
      App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify, ),
      'new recipe instance';
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
    ok my $reader = App::Transfer::Reader->load(
        {
            transfer  => $transfer,
            header    => \@header,
            tempfield => $tempfield,
            rectangle => $rectangle,
            reader    => 'xls',
            options   => $options,
        }
      ),
      'new reader spreadsheet object';
    is $reader->input_file,   't/rectangle.xls',   'xls file name';
    is $reader->worksheet,    1,                   'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'A5', 'F9' ], 'siruta data rectangle';
    cmp_deeply $reader->rect_o,    [ 1,    5 ],    'rext min col, min row';
    cmp_deeply $reader->rect_v,    [ 6,    9 ],    'rext max col, max row';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $i = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        cmp_deeply $rec, $expected_3->[$i], "record $i data ok";
        $i++;
    }
    is $i, 5, 'compared all records';
    is $reader->record_count, $i, 'counted records match record_count';
};

subtest 'Full range - dynamic rectangle lower left corner' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls-rect-4.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new( debug => 1 );
    my $options_href = { input_file => 't/rectangle.xls',  };
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
        reader    => 'xls',
        options   => $options,
    }), 'new reader spreadsheet object';
    is $reader->input_file, 't/rectangle.xls', 'xls file name';
    is $reader->worksheet, 1, 'worksheet name';
    isa_ok $reader->workbook, 'Spreadsheet::Read', 'workbook';

    cmp_deeply $reader->rectangle, [ 'A5', 'END' ],
        'siruta data rectangle';
    cmp_deeply $reader->rect_o, [1,5],'rext min col, min row';
    cmp_deeply $reader->rect_v, [6,12],'rext max col, max row';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $i = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        cmp_deeply $rec, $expected->[$i], "record $i data ok";
        $i++;
    }
    is $i, 5, 'compared all records';
    is $reader->record_count, $i, 'counted records match record_count';
};

done_testing;
