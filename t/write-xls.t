#
# Test the XLS writer
#
use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most; # skip_all => "Until we meet again";
use Test::File::Contents;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Writer::xls';
    use_ok $CLASS or die;
}

my $output_path = 't/output';
my $output_file = 'alba.xls';
my $output      = path $output_path, $output_file;

subtest 'Write XLS file - set output path/file' => sub {
    my $recipe_file = path(qw(t recipes recipe-xls-write.conf));
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    isa_ok $transfer, 'App::Transfer', 'transfer';
    my $reader_opts_href = {};
    my $writer_opts_href = {
        output_file => $output_file,
        output_path => $output_path,
        debug       => 0,
    };
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe, 'App::Transfer::Recipe', 'recipe';
    ok my $reader_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $reader_opts_href,
        rw_type   => 'reader',
    ), 'reader options';
    ok my $writer_options = App::Transfer::Options->new(
        transfer  => $transfer,
        recipe    => $recipe,
        options   => $writer_opts_href,
        rw_type   => 'writer',
    ), 'writer options';
    isa_ok $reader_options, 'App::Transfer::Options', 'reader options';
    isa_ok $writer_options, 'App::Transfer::Options', 'writer options';
    ok my $header = $recipe->table->dst_header, 'the header';
    ok my $writer = App::Transfer::Writer->load( {
        transfer => $transfer,
        header   => $header,
        writer   => 'xls',
        reader_options => $reader_options,
        writer_options => $writer_options,
    } ), 'new writer xls object';
    isa_ok $writer, 'App::Transfer::Writer', 'writer';
    is $writer->output_file, $output_file, 'xls file name';
    is $writer->output_path, $output_path, 'xls file name';
    is $writer->output, $output, 'xls path and file name';
    lives_ok { $writer->insert_header( [qw(siruta denloc sirsup jud codp)] ) }
    'insert header';
    my $row_1 = {
        siruta => 10,
        denloc => "JUDEȚUL ALBA",
        sirsup => 1,
        jud    => 1,
        codp   => 0,
    };
    my $row_2 = {
        siruta => 1026,
        denloc => "ALBA IULIA",
        sirsup => 1017,
        jud    => 1,
        codp   => 0,
    };
    lives_ok { $writer->insert($row_1) } 'insert row 1';
    lives_ok { $writer->insert($row_2) } 'insert row 2';
    lives_ok { $writer->finish } 'finish';
    is $writer->records_inserted, 2, 'records inserted: 2';
    is $writer->records_skipped, 0, 'records skipped: 0';
};

unlink $output or warn "unlink output $output: $!";

done_testing;
