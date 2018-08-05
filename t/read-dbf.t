#
# Test the DBF reader
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
    $CLASS = 'App::Transfer::Reader::dbf';
    use_ok $CLASS or die;
}

subtest 'DBF OK' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/siruta.dbf', };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'reader',
    );
    ok my $header = $recipe->table->src_header, 'get the recipe table header';
    my $tmpfld = $recipe->table->tempfield;
    ok my $reader = App::Transfer::Reader->load( {
        transfer => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader   => 'dbf',
        options  => $options,
    } ), 'new reader dbf object';
    is $reader->input_file, 't/siruta.dbf', 'dbf file name';

    my $expecting_rec_17 = {
        SIRUTA => 13515,
        DENLOC => "VALEA RUMANESTILOR",
        CODP   => 115101,
        JUD    => 3,
        SIRSUP => 13490,
        TIP    => 10,
        NIV    => 3,
        MED    => 1,
        FSJ    => 1,
        FSL    => 321696512951, 
        RANG   => "V",
    };

    ok my $aoh = $reader->_contents, 'get contents';
    cmp_deeply $aoh->[17], $expecting_rec_17, 'record 17 data looks good';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $count = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        if ($count == 17) {
            cmp_deeply $rec, $expecting_rec_17, 'record 17 data ok';
        }
        $count++;
    }

    is $reader->record_count, $count, 'counted records match record_count';
};

subtest 'DBF unknown fields' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-dbf2.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/siruta.dbf', };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'reader',
    );
    ok my $header = $recipe->table->src_header, 'get the recipe table header';
    my $tmpfld = $recipe->table->tempfield;
    ok my $reader = App::Transfer::Reader->load( {
        transfer => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader   => 'dbf',
        options  => $options,
    } ), 'new reader dbf object';
    is $reader->input_file, 't/siruta.dbf', 'dbf file name';
    throws_ok { $reader->contents_iter }
        qr/\QHeader map <--> DBF file header inconsistency/,
        'Should get an exception for header map - file header inconsistency';
};


done_testing;
