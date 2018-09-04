#
# Test the CSV reader
#
use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;
use App::Transfer::Reader;

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
    ok my $header = $recipe->table->src_header, 'get the recipe table header';

    my $tmpfld = $recipe->table->tempfield;
    ok my $reader = App::Transfer::Reader->load( {
        transfer  => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader    => 'csv',
        options   => $options,
    } ), 'new reader csv object';
    is $reader->input_file, 't/siruta.csv', 'csv file name';

    my $expecting_idx_0 = {
        CODP   => 0,
        DENLOC => "JUDEŢUL ALBA",
        FSJ    => 1,
        FSL    => 100000000000,
        JUD    => 1,
        MED    => 0,
        NIV    => 1,
        RANG   => undef,
        SIRSUP => 1,
        SIRUTA => 10,
        TIP    => 40,
    };

    my $expecting_idx_14 = {
        SIRUTA => 13515,
        DENLOC => "VALEA RUMÂNEŞTILOR",
        CODP   => 115101,
        JUD    => 3,
        SIRSUP => 13490,
        TIP    => 10,
        NIV    => 3,
        MED    => 1,
        FSJ    => 3,
        FSL    => 321696512951,
        RANG   => "V",
    };

    ok my $aoh = $reader->_contents, 'get contents';
    is $aoh->[0], $expecting_idx_0, 'record 1 data looks good';
    is $aoh->[14], $expecting_idx_14, 'record 15 data looks good';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, ['MooseX::Iterator::Array'], 'iterator';

    my $count = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        if ($count == 0) {
            is $rec, $expecting_idx_0, 'record 1 data ok';
        }
        if ($count == 14) {
            is $rec, $expecting_idx_14, 'record 15 data ok';
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
    ok my $header = $recipe->table->src_header, 'get the recipe table header';
    my $tmpfld = $recipe->table->tempfield;
    ok my $reader = App::Transfer::Reader->load( {
        transfer  => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader    => 'csv',
        options   => $options,
    } ), 'new reader csv object';
    is $reader->input_file, 't/siruta-lower.csv', 'csv file name';

    like(
        dies { $reader->contents_iter },
        qr/^Recipe header/,
        'Should get an exception for recipe header - file inconsistency'
    );
};

subtest 'CSV - recipe with tempfield' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-csv2db-2.conf' ),
        "recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/factura.csv', };
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
    is $tmpfld, ['seria'], '';
    ok my $reader = App::Transfer::Reader->load( {
        transfer  => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader    => 'csv',
        options   => $options,
    } ), 'new reader csv object';
    is $reader->input_file, 't/factura.csv', 'csv file name';

    my $expecting = {
        firma     => 7,
        mod_plata => 3,
        factura   => "18 F 05000038",
        data      => "21.01.2018",
        scadenta  => "05.02.2018",
        suma      => 10.84,
        seria     => undef,
    };

    ok my $aoh = $reader->_contents, 'get contents';
    is $aoh->[0], $expecting, 'record 1 data looks good';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, ['MooseX::Iterator::Array'], 'iterator';

    my $count = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        is $rec, $expecting, 'record 1 data ok';
        $count++;
    }

    is $reader->record_count, $count, 'counted records match record_count';
};

done_testing;
