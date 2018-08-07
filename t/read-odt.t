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
    $CLASS = 'App::Transfer::Reader::odt';
    use_ok $CLASS or die;
}

subtest 'ODT OK' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-odt.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/judete.odt', };
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';
    my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'reader',
    );
    ok my $header = $recipe->table->src_header, 'get the recipe table header';
    use Data::Dump; dd $header;
    my $tmpfld = $recipe->table->tempfield;
    ok my $reader = App::Transfer::Reader->load( {
        transfer  => $transfer,
        header    => $header,
        tempfield => $tmpfld,
        reader    => 'odt',
        options   => $options,
    } ), 'new reader odt object';
    is $reader->input_file, 't/judete.odt',        'odt file name';
    isa_ok $reader->doc,    'ODF::lpOD::Document', 'doc';

    my $expecting_rec_41 = {
        codjudet        => 42,
        denumirejudet   => "GIURGIU",
        factordesortare => 19,
        mnemonic        => "GR",
        zona            => 3
    };

    ok my $aoh = $reader->_contents, 'get contents';
    cmp_deeply $aoh->[41], $expecting_rec_41, 'record 41 data looks good';

    ok my $iter = $reader->contents_iter, 'get the iterator';
    isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

    my $count = 0;
    while ( $iter->has_next ) {
        my $rec = $iter->next;
        if ($count == 41) {
            cmp_deeply $rec, $expecting_rec_41, 'record 41 data ok';
        }
        $count++;
    }

    is $reader->record_count, $count, 'counted records match record_count';
};

subtest 'ODT unknown fields' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-odt2.conf' ),
        "Recipe file";
    my $transfer = App::Transfer->new;
    my $options_href = { input_file => 't/judete.odt', };
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
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
        reader    => 'odt',
        options   => $options,
    } ), 'new reader odt object';
    is $reader->input_file, 't/judete.odt',        'odt file name';
    isa_ok $reader->doc,    'ODF::lpOD::Document', 'doc';

    throws_ok { $reader->contents_iter }
        qr/\QHeader map <--> ODT file header inconsistency/,
        'Should get an exception for header map - file header inconsistency';
};

done_testing;
