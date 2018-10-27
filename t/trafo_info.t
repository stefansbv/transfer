use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use Locale::TextDomain qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

#use App::Transfer;
use App::Transfer::Transform::Info;
use lib 't/lib';

binmode STDOUT, ':utf8';

use Capture::Tiny 0.12 qw(capture_stdout capture_merged);

$ENV{TRANSFER_LOG_CONFIG} = 't/log.conf';

my $input  = __('Input:');
my $output = __('Output:');
my $recipe = __('Recipe:');
my $workin = __('Working:');
my $worked = __('source records read:');
my $summar = __('Summary:');

subtest 'Test the transfer info methods' => sub {
    ok my $trafo = App::Transfer::Transform::Info->new,
        'new trafo info instance';

    like(
        capture_stdout {
            $trafo->job_intro(
                name          => 'Name',
                version       => 1,
                syntaxversion => 2,
                description   => 'Description',
              )
        },
        qr/$recipe/ms,
        'job_intro should work'
    );

    like(
        capture_stdout {
            $trafo->job_info_input_file('file.csv');
        },
        qr/$input/,
        'job_info_input_file should work'
    );

    like(
        capture_stdout {
            $trafo->job_info_output_file('file.csv');
        },
        qr/$output/,
        'job_info_output_file should work'
    );

    like(
        capture_stdout {
            $trafo->job_info_input_db('table', 'database');
        },
        qr/$input/,
        'job_info_input_db should work'
    );

    like(
        capture_stdout {
            $trafo->job_info_output_db('table', 'database');
        },
        qr/$output/,
        'job_info_output_db should work'
    );

    like( capture_stdout { $trafo->job_info_prework },
        qr/$workin/ms, 'job_intro_prework should work');

    like( capture_stdout { $trafo->job_info_postwork(100) },
        qr/$worked/ms, 'job_intro_post should work');

    like( capture_stdout { $trafo->job_summary(100, 0) },
        qr/$summar/ms, 'job_summary should work');

};

done_testing;
