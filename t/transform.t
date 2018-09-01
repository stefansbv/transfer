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

my $input  = __('Input:');
my $output = __('Output:');
my $trans3 = __('Working:');
my $trans4 = __('Summary:');

# subtest 'attributes - recipe with columns section and hash header' => sub {
#     my $uri            = 'db:pg://@localhost/__transfertest__';
#     my $recipe_file    = path( 't', 'recipes', 'table','recipe-1.conf' );
#     my $input_options  = { input_uri  => $uri };
#     my $output_options = { output_uri => $uri };
#     my $trafo_params   = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new( debug => 1 );
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => $input_options,
#         output_options => $output_options,
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
#     isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

#     ok $trafo->exists_in_type('split'), '"split" exists in type';
#     ok !$trafo->exists_in_type('nosuchtype'), '"nosuchtype" does not exists_in_type';

#     my $bag1 = bag { item 'id'; item 'denumire'; end; };
#     is $trafo->src_header, $bag1, 'src_header';
#     is $trafo->dst_header, $bag1, 'dst_header';
#     is $trafo->num_fields, 2, 'number of fields in the header map';

#     # for my $pair ( $self->field_pairs ) {
#     #     $new->{ $pair->[0] } = $rec->{ $pair->[1] };
#     # }

#     my $expected_id_info = {
#         pos    => 1,
#         name   => "id",
#         type   => "integer",
#         length => 2,
#         prec   => "",
#         scale  => "",
#     };

#     ok !$trafo->has_no_columns_info, 'column info';
#     is $trafo->get_column_info('id'), $expected_id_info, 'column info for "id"';

#     ok my @fields = $trafo->all_ordered_fields, 'get all ordered fields';
#     is \@fields, [qw(id denumire)], 'fields order match';

#     is $trafo->has_common_headers, 1, 'has common headers';
# };

# subtest 'attributes - recipe w/o columns section and with array header' => sub {
#     my $uri            = 'db:pg://@localhost/__transfertest__';
#     my $recipe_file    = path( 't', 'recipes', 'table','recipe-3.conf' );
#     my $input_options  = { input_uri  => $uri };
#     my $output_options = { output_uri => $uri };
#     my $trafo_params   = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => $input_options,
#         output_options => $output_options,
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
#     isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

#     ok $trafo->exists_in_type('split'), 'exists_in_type';

#     my $bag1 = bag { item 'id'; item 'denumire'; end; };
#     is $trafo->src_header, $bag1, 'src_header';
#     is $trafo->dst_header, $bag1, 'dst_header';
#     is $trafo->num_fields, 2, 'number of fields in the header map';

#     ok $trafo->has_no_columns_info, 'column info';
#     is $trafo->get_column_info('id'), undef, 'column info for "id"';

#     my @fields = $trafo->all_ordered_fields;
#     is \@fields, [], 'fields order match';
# };

subtest 'transform: column_type_trafos' => sub {
    my $uri            = 'db:pg://@localhost/__transfertest__';
    my $recipe_file    = path( 't', 'recipes', 'recipe-db.conf' );
    my $input_options  = { input_uri  => $uri };
    my $output_options = { output_uri => $uri };
    my $trafo_params   = [ recipe_file => $recipe_file ];

    ok my $transfer = App::Transfer->new, 'transfer instance';
    isa_ok $transfer, ['App::Transfer'], 'is a transfer instance';

    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';
    isa_ok $trafo->transfer, ['App::Transfer'], 'is a transfer instance';

    # my $bag1 = bag { item 'id'; item 'denumire'; end; };
    # is $trafo->src_header, $bag1, 'src_header';
    # is $trafo->dst_header, $bag1, 'dst_header';
    # is $trafo->num_fields, 2, 'number of fields in the header map';

    # like(
    #     capture_stdout {
    #         dies { $trafo->job_info_input_file }
    #     }, qr/$input/,
    #     'Should have error for missing input file option or configuration'
    # );

    # like(
    #     capture_stdout {
    #         dies { $trafo->job_info_output_file }
    #     },
    #     qr/$output/,
    #     'Should have error for missing output file option or configuration'
    # );

    # like( capture_stdout { $trafo->job_info_work },
    #     qr/$trans3/ms, 'job_intro should work');

    # like( capture_stdout { $trafo->job_summary },
    #     qr/$trans4/ms, 'job_summary should work');


    is $trafo->recipe_file,    $recipe_file,    'has recipe file';
    is $trafo->input_options,  $input_options,  'has input options';
    is $trafo->output_options, $output_options, 'has output options';
    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'is a transfer recipe';
    is $trafo->tempfields, [], 'no tempfields';

    isa_ok $trafo->reader, ['App::Transfer::Reader'], 'transfer reader';
    isa_ok $trafo->writer, ['App::Transfer::Writer'], 'transfer writer';
    isa_ok $trafo->plugin_column, ['App::Transfer::Plugin'], 'transfer plugin column';
    isa_ok $trafo->plugin_column_type, ['App::Transfer::Plugin'],
      'transfer plugin column type';
    is $trafo->io_trafo_type( 'csv', 'db' ), 'csv2db', 'csv and db';

    my $info = {
        f_blob => {
            pos         => 1,
            name        => 'f_blob',
            type        => 'blob',
            defa        => undef,
            is_nullable => undef,
            length      => 1,
            prec        => '',
            scale       => '',
        },
        f_char => {
            pos         => 2,
            name        => 'f_char',
            type        => 'char',
            defa        => undef,
            is_nullable => undef,
            length      => 10,
            prec        => '',
            scale       => '',
        },
        f_date => {
            pos         => 3,
            name        => 'f_date',
            type        => 'date',
            defa        => undef,
            is_nullable => undef,
            length      => 10,
            prec        => '',
            scale       => '',
        },
        f_int => {
            pos         => 4,
            name        => 'f_int',
            type        => 'integer',
            defa        => undef,
            is_nullable => undef,
            length      => '',
            prec        => '',
            scale       => '',
        },
        f_num => {
            pos         => 5,
            name        => 'f_num',
            type        => 'numeric',
            defa        => undef,
            is_nullable => undef,
            length      => '',
            prec        => 8,
            scale       => 2,
        },
        f_sint => {
            pos         => 6,
            name        => 'f_sint',
            type        => 'smallint',
            defa        => undef,
            is_nullable => undef,
            length      => 1,
            prec        => '',
            scale       => '',
        },
        f_text => {
            pos         => 7,
            name        => 'f_text',
            type        => 'text',
            defa        => undef,
            is_nullable => undef,
            length      => 1,
            prec        => '',
            scale       => '',
        },
        f_stmp => {
            pos         => 8,
            name        => 'f_stmp',
            type        => 'timestamp',
            defa        => undef,
            is_nullable => undef,
            length      => 24,
            prec        => '',
            scale       => '',
        },
        f_vchr => {
            pos         => 9,
            name        => 'f_vchr',
            type        => 'varchar',
            defa        => undef,
            is_nullable => undef,
            length      => 100,
            prec        => '',
            scale       => '',
        },
    };

    ok $trafo->set_column_info( %{$info} ), 'set the column info';

    # use Data::Dump;
    # my @fp = $trafo->field_pairs;
    # dd @fp;

    ok !$trafo->has_no_columns_info, 'column info';
    is $trafo->get_column_info('f_vchr'), $info->{f_vchr},
      'column info for "f_vchr"';

    my $actual_info = {};
    for my $pair ( $trafo->column_info_pairs ) {
        $actual_info->{ $pair->[0] } = $pair->[1];
    }
    is $actual_info, $info, 'filed info match';

    my $original_record = {
        f_blob => 'A long long, not so long text blob',
        f_char => 'A',
        f_date => '21.08.2018',
        f_int  => -2300125,
        f_num  => 51720.100,
        f_sint => 2301,
        f_text => 'A long long, not so long text text',
        f_stmp => '31.01.2014, 18:30:34:000',
        f_vchr => 'a variable character type',
    };
    my $expected_record = {
        f_blob => 'A long long, not so long text blob',
        f_char => 'A',
        f_date => '2018-08-21',
        f_int  => -2300125,
        f_num  => 51720.100,
        f_sint => 2301,
        f_text => 'A long long, not so long text text',
        f_stmp => '2014-01-31T18:30:34:000',
        f_vchr => 'a variable character type',
    };

    my $record = $trafo->column_type_trafos( $original_record, 'logstr' );

    is $record, $expected_record, 'test column_type_trafos';

    # like(
    #     dies { $trafo->reader->contents_iter },
    #     qr/(database|server)( .+)? not (found|available)/,
    #     'Should have error for missing database'
    # );
    # TODO: other subtest for this:
    # try_ok {$trafo->transfer_db2db} 'transfer file to file';
    # header_map
};

# #--- Validations

# # <source>
# #   reader              = csv
# #   file                = test-file.csv
# # </source>
# subtest 'validate file src - wrong input file from the recipe' => sub {
#     my $recipe_file  = path(qw(t recipes table recipe-5.conf));
#     my $trafo_params = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => {},
#         output_options => {},
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     is $trafo->get_logfield_name, 'pos', 'log field name';

#     my $msg = __("Invalid input file specified; use '--if' or fix the source file in the recipe.");
#     like(
#         dies { $trafo->validate_file_src },
#         qr/$msg/,
#         'validate input: wrong input from the recipe'
#     );
# };

# # <source>
# #   reader              = dbf
# #   file                =
# # </source>
# subtest 'validate file src - no input file from the recipe' => sub {
#     my $recipe_file  = path(qw(t recipes recipe-dbf2.conf));
#     my $trafo_params = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => {},
#         output_options => {},
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     my $msg = __("No input file specified; use '--if' or set the source file in the recipe.");
#     like(
#         dies { $trafo->validate_file_src },
#         qr/$msg/,
#         'validate input: no input from the recipe'
#     );
# };

# # <destination>
# #   writer              = csv
# #   file                = t/nonexistentoutput/test-file.csv
# # </destination>
# subtest 'validate file dst - wrong output path from file name in the recipe' => sub {
#     my $recipe_file  = path(qw(t recipes table recipe-5.conf));
#     my $trafo_params = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => {},
#         output_options => {},
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     my $msg = __("Invalid output file specified; use '--of' or fix the destination file in the recipe.");
#     like(
#         dies { $trafo->validate_file_dst },
#         qr/$msg/,
#         'validate output: no output from the recipe'
#     );
# };

# TODO: decide how to handle file and path configs in the recipe
# <destination>
#   writer              = csv
#   file                = test-file.csv
#   path                = t/nonexistentoutput
# </destination>
# subtest 'validate file dst - wrong output path from the recipe' => sub {
#     my $recipe_file  = path(qw(t recipes recipe-6.conf));
#     my $trafo_params = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => {},
#         output_options => {},
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     my $msg = __("Invalid output file specified; use '--of' or fix the destination file in the recipe.");
#     like(
#         dies { $trafo->validate_file_dst },
#         qr/$msg/,
#         'validate output: no output from the recipe'
#     );
# };

# #  <destination>
# #   writer              = dbf
# #   file                =
# # </destination>
# subtest 'validate file dst - no output file from the recipe' => sub {
#     my $recipe_file  = path(qw(t recipes recipe-dbf3.conf));
#     my $trafo_params = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => {},
#         output_options => {},
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     my $msg = __("No output file specified; use '--of' or set the destination file in the recipe.");
#     like(
#         dies { $trafo->validate_file_dst },
#         qr/$msg/,
#         'validate output: no output from the recipe'
#     );
# };

# # <source>
# #   reader              = fake_db
# #   target              = test
# #   table               = test_db
# # </source>
# subtest 'validate db src - wrong ... from the recipe' => sub {
#     my $uri            = 'db:pg://@localhost/nonexistent';
#     my $recipe_file    = path( 't', 'recipes', 'recipe-fake_db.conf' );
#     my $input_options  = { input_uri  => $uri };
#     my $output_options = { output_uri => $uri };
#     my $trafo_params   = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => $input_options,
#         output_options => $output_options,
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
#     isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

#     # $trafo->validate_db_src;

#     # my $msg = __("Invalid input.");
#     # like(
#     #     dies { $trafo->validate_db_src },
#     #     qr/$msg/,
#     #     'validate input: wrong input from the recipe'
#     # );
# };

# subtest 'transfer file2file' => sub {
#     my $input_options  = { input_file  => path(qw(t siruta.csv)) };
#     my $output_options = { output_file => path(qw(t output.csv)) };
#     my $recipe_file    = path(qw(t recipes table recipe-5.conf));
#     my $trafo_params   = [ recipe_file => $recipe_file ];

#     my $transfer = App::Transfer->new;
#     isa_ok $transfer, ['App::Transfer'], 'transfer instance';
#     ok my $trafo = App::Transfer::Transform->new(
#         transfer       => $transfer,
#         input_options  => $input_options,
#         output_options => $output_options,
#         @{$trafo_params},
#     ), 'new trafo instance';
#     isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

#     is $trafo->get_logfield_name, 'pos', 'log field name';

#     my $merged;
#     like(
#         $merged = capture_merged { $trafo->validate_file_src },
#         qr/$input/,
#         'transfer file to file'
#     );
#     diag $merged if $ENV{TRANSFER_DEBUG};
#     like(
#         $merged = capture_merged { $trafo->validate_file_dst },
#         qr/$output/,
#         'transfer file to file'
#     );
#     diag $merged if $ENV{TRANSFER_DEBUG};
# };

done_testing;
