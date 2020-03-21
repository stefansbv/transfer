#
# Test the JSON writer
#
use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most;
use Test::File::Contents;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Writer::json';
    use_ok $CLASS or die;
}

my $output_path = 't/output';
my $output_file = 'siruta.json';
my $output      = path $output_path, $output_file;

my $json_text = <<'END_TXT';
{
   "siruta" : 10,
   "denloc" : "JUDETUL ALBA",
   "sirsup" : 1,
   "jud"    : 1,
   "codp"   : 0,
}
END_TXT

subtest 'Write JSON file - set output path/file' => sub {
    my $recipe_file = path(qw(t recipes recipe-json-write.conf));
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
        writer   => 'json',
        reader_options => $reader_options,
        writer_options => $writer_options,
    } ), 'new writer json object';
    isa_ok $writer, 'App::Transfer::Writer', 'writer';
    is $writer->output_file, $output_file, 'json file name';
    is $writer->output_path, $output_path, 'json file name';
    is $writer->output, $output, 'json path and file name';
    my $row = {
        siruta => 10,
        denloc => "JUDETUL ALBA",
        sirsup => 1,
        jud    => 1,
        codp   => 0,
    };
    lives_ok { $writer->insert($row) } 'insert row';
    lives_ok { $writer->finish } 'finish';
    is $writer->records_inserted, 1, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';
  TODO: {
        todo_skip "Test output for json: compare properly", 1;
        file_contents_eq_or_diff( $output, $json_text,
            { encoding => 'UTF-8' } );
    }
};

# unlink $output or warn "unlink output $output: $!";

done_testing;
