use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
#use Locale::TextDomain qw(App-Transfer);

use App::Transfer;
use App::Transfer::Transform;
use lib 't/lib';

binmode STDOUT, ':utf8';

$ENV{TRANSFER_LOG_CONFIG} = 't/log.conf';

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
        dies { $trafo->job_info_input_file },
        qr/The file reader must have a valid/,
        'Should have error for missing file option or configuration'
    );

    like(
        dies { $trafo->job_info_output_file },
        qr/The file writer must have a valid/,
        'Should have error for missing file option or configuration'
    );

    ok( lives { $trafo->job_info_work },
        'Should have no error for missing parameters' );

    ok( lives { $trafo->job_summary },
        'Should have no error for missing parameters' );

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
    isa_ok $trafo->plugin, ['App::Transfer::Plugin'], 'transfer plugin';
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
    my $recipe_file    = path(qw(t recipes invalid recipe-fake.conf));
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';

    is $trafo->get_logfield_name, 'siruta', 'log field name';
        
    ok( lives { $trafo->transfer_file2file }, 'transfer file to file' ); 

    # $trafo->type_join($step, $record, $logstr);

};

done_testing;
