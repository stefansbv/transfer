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
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv2db.conf' ),
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
    ok my $reader = App::Transfer::Reader->load( {
        transfer => $transfer,
        recipe   => $recipe,
        reader   => 'csv',
        options  => $options,
    } ), 'new reader csv object';
    is $reader->input_file, 't/siruta.csv', 'csv file name';

    my $expecting_rec_15 = {
        siruta => 13515,
        denloc => "VALEA RUMÂNEŞTILOR",
        codp   => 115101,
        jud    => 3,
        sirsup => 13490,
        tip    => 10,
        niv    => 3,
        med    => 1,
        fsj    => 3,
        fsl    => 321696512951, 
        rang   => "V",
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

subtest 'CSV with lc header' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv2db.conf' ),
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
    ok my $reader = App::Transfer::Reader->load( {
        transfer => $transfer,
        recipe   => $recipe,
        reader   => 'csv',
        options  => $options,
    } ), 'new reader csv object';
    is $reader->input_file, 't/siruta-lower.csv', 'csv file name';
    throws_ok { $reader->contents_iter }
        qr/\QHeader map <--> CSV file header inconsistency/,
        'Should get an exception for header map - file header inconsistency';
};

done_testing;
