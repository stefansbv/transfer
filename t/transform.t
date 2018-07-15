use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use Locale::TextDomain qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

use App::Transfer;
use App::Transfer::Transform;
use lib 't/lib';

binmode STDOUT, ':utf8';

use Capture::Tiny 0.12 qw(capture_stdout capture_merged);

$ENV{TRANSFER_LOG_CONFIG} = 't/log.conf';

my $trans1 = __('Input:');
my $trans2 = __('Output:');
my $trans3 = __('Working:');
my $trans4 = __('Summary:');

subtest 'DB to DB transfer' => sub {
    my $uri            = 'db:pg://@localhost/__transfertest__';
    my $recipe_file    = path( 't', 'recipes', 'recipe-db.conf' );
    my $input_options  = { input_uri  => $uri };
    my $output_options = { output_uri => $uri };
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
        ),
        'new trafo instance';

    like(
        capture_stdout {
            dies { $trafo->job_info_input_file }
        }, qr/$trans1/,
        'Should have error for missing file option or configuration'
    );

    like(
        capture_stdout {
            dies { $trafo->job_info_output_file }
        },
        qr/$trans2/,
        'Should have error for missing file option or configuration'
    );

    like( capture_stdout { $trafo->job_info_work },
        qr/$trans3/ms, 'job_intro should work');

    like( capture_stdout { $trafo->job_summary },
        qr/$trans4/ms, 'job_intro should work');

    isa_ok $trafo->transfer, ['App::Transfer'], 'is a transfer instance';
    is $trafo->recipe_file,    $recipe_file,    'has recipe file';
    is $trafo->input_options,  $input_options,  'has input options';
    is $trafo->output_options, $output_options, 'has output options';
    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'is a transfer recipe';
    is $trafo->tempfields, [], 'no tempfields';
    my $reader_opts = {
        transfer => $trafo->transfer,
        recipe   => $trafo->recipe,
        options  => { input_uri => $uri },
        rw_type  => 'reader',
    };
    is $trafo->reader_options, $reader_opts, 'reader options';
    my $writer_opts = {
        transfer => $trafo->transfer,
        recipe   => $trafo->recipe,
        options  => { output_uri => $uri },
        rw_type  => 'writer',
    };
    is $trafo->writer_options, $writer_opts, 'writer options';
    isa_ok $trafo->reader, ['App::Transfer::Reader'], 'transfer reader';
    isa_ok $trafo->writer, ['App::Transfer::Writer'], 'transfer writer';
    isa_ok $trafo->plugin_row, ['App::Transfer::Plugin'], 'transfer plugin';
    isa_ok $trafo->plugin_column, ['App::Transfer::Plugin'], 'transfer plugin column';
    isa_ok $trafo->plugin_column_type, ['App::Transfer::Plugin'], 'transfer plugin column type';
    is $trafo->io_trafo_type('csv', 'db'), 'csv2db', 'csv and db';
    like(
        dies { $trafo->reader->contents_iter },
        qr/(database|server)( .+)? not (found|available)/,
        'Should have error for missing database'
    );
    # TODO: other subtest for this:
    # try_ok {$trafo->transfer_db2db} 'transfer file to file';
};

subtest 'File2file transfer' => sub {
    my $input_options  = { input_file  => path(qw(t siruta.csv)) };
    my $output_options = { output_file => path(qw(t output.csv)) };
    my $recipe_file    = path(qw(t recipes recipe-fake.conf));
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';

    is $trafo->get_logfield_name, 'siruta', 'log field name';

    like(
        capture_merged { $trafo->transfer_file2file },
        qr/$trans1/,
        'transfer file to file'
    );

    # $trafo->type_join($step, $record, $logstr);

};

done_testing;
