#
# Test the CSV writer
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
    $CLASS = 'App::Transfer::Writer::csv';
    use_ok $CLASS or die;
}

my $output_file = 't/output/siruta.csv';

subtest 'CSV OK' => sub {
    my $recipe_file = path(qw(t recipes recipe-csv-write.conf));
    my $transfer = App::Transfer->new;
    isa_ok $transfer, 'App::Transfer', 'transfer';
    my $options_href = { output_file => $output_file, };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe, 'App::Transfer::Recipe', 'recipe';
    ok my $options = App::Transfer::Options->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $options_href,
        rw_type  => 'writer',
    ), 'new options instance';
    isa_ok $options, 'App::Transfer::Options', 'options';
    ok my $writer = App::Transfer::Writer->load(
        {   transfer => $transfer,
            recipe   => $recipe,
            writer   => 'csv',
            options  => $options,
        } ), 'new writer csv object';
    isa_ok $writer, 'App::Transfer::Writer', 'writer';
    is $writer->output_file, $output_file, 'csv file name';
    lives_ok { $writer->insert_header } 'insert header';
    my $row = {
        codp   => 0,
        denloc => "JUDETUL ALBA",
        fsj    => 1,
        fsl    => 100000000000,
        jud    => 1,
        med    => 0,
        niv    => 1,
        rang   => "",
        sirsup => 1,
        siruta => 10,
        tip    => 40,
    };
    lives_ok {
        $writer->insert( 'table', $row )
    } 'insert row';
    lives_ok { $writer->finish } 'finish';
    is $writer->records_inserted, 1, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';

};

# unlink $output_file;

done_testing;
