#
# Test the CSV writer
#
use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::Most;
use Test::File::Contents;
use Test::Warn;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Writer::csv';
    use_ok $CLASS or die;
}

my $output_path = 't/output';
my $output_file = 'siruta.csv';
my $output      = path $output_path, $output_file;

my $csv_text = <<'END_TXT';
siruta;denloc;sirsup;jud;codp
10;"JUDEȚUL ALBA";1;1;0
END_TXT

subtest 'Write CSV file - set output path/file' => sub {
    my $recipe_file = path(qw(t recipes recipe-csv-write.conf));
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
    my $header;
    warning_like { $header = $recipe->table->dst_header }
        qr/Deprecated name attribute/i,
        "an unknown parameter test";
    ok my $writer = App::Transfer::Writer->load( {
        transfer => $transfer,
        header   => $header,
        writer   => 'csv',
        reader_options => $reader_options,
        writer_options => $writer_options,
    } ), 'new writer csv object';
    isa_ok $writer, 'App::Transfer::Writer', 'writer';
    is $writer->output_file, $output_file, 'csv file name';
    is $writer->output_path, $output_path, 'csv file name';
    is $writer->output, $output, 'csv path and file name';
    lives_ok { $writer->insert_header( [qw(siruta denloc sirsup jud codp)] ) }
    'insert header';
    my $row = {
        siruta => 10,
        denloc => "JUDEȚUL ALBA",
        sirsup => 1,
        jud    => 1,
        codp   => 0,
    };
    lives_ok {
        $writer->insert( 'table', $row )
    } 'insert row';
    lives_ok { $writer->finish } 'finish';
    is $writer->records_inserted, 1, 'records inserted: 1';
    is $writer->records_skipped, 0, 'records skipped: 0';
    file_contents_eq_or_diff(
        $output,
        $csv_text,
        { encoding => 'UTF-8' }
    );
};

unlink $output or warn "unlink output $output: $!";

done_testing;
