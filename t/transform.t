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

my $tr_input  = __('Input:');
my $tr_output = __('Output:');
my $tr_workin = __('Working:');
my $tr_summar = __('Summary:');

my $output_path = 't/output';
my $output_file = 'output.csv';
my $output      = path $output_path, $output_file;

subtest 'attributes - recipe with columns section and hash header' => sub {
    my $uri            = 'db:pg://@localhost/__transfertest__';
    my $recipe_file    = path( 't', 'recipes', 'table','recipe-1.conf' );
    my $input_options  = { input_uri  => $uri };
    my $output_options = { output_uri => $uri };
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new( debug => 1 );
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

    ok $trafo->exists_in_type('split'), '"split" exists in type';
    ok !$trafo->exists_in_type('nosuchtype'), '"nosuchtype" does not exists_in_type';

    my $bag1 = bag { item 'id'; item 'denumire'; end; };
    is $trafo->src_header, $bag1, 'src_header';
    is $trafo->dst_header, $bag1, 'dst_header';

    # for my $pair ( $self->field_pairs ) {
    #     $new->{ $pair->[0] } = $rec->{ $pair->[1] };
    # }

    my $expected_id_info = {
        pos    => 1,
        name   => "id",
        type   => "integer",
        length => 2,
        prec   => "",
        scale  => "",
    };

    ok !$trafo->has_no_columns_info, 'column info';
    is $trafo->get_column_info('id'), $expected_id_info, 'column info for "id"';

    ok my @fields = $trafo->all_ordered_fields, 'get all ordered fields';
    is \@fields, [qw(id denumire)], 'fields order match';

    is $trafo->has_common_headers, 1, 'has common headers';
};

subtest 'attributes - recipe w/o columns section and with array header' => sub {
    my $uri            = 'db:pg://@localhost/__transfertest__';
    my $recipe_file    = path( 't', 'recipes', 'table','recipe-3.conf' );
    my $input_options  = { input_uri  => $uri };
    my $output_options = { output_uri => $uri };
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

    ok $trafo->exists_in_type('split'), 'exists_in_type';

    my $bag1 = bag { item 'id'; item 'denumire'; end; };
    is $trafo->src_header, $bag1, 'src_header';
    is $trafo->dst_header, $bag1, 'dst_header';

    ok $trafo->has_no_columns_info, 'column info';
    is $trafo->get_column_info('id'), undef, 'column info for "id"';

    my @fields = $trafo->all_ordered_fields;
    is \@fields, [], 'fields order match';
};

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

    my $bag1 = bag { item 'id'; item 'denumire'; end; };
    is $trafo->src_header, $bag1, 'src_header';
    is $trafo->dst_header, $bag1, 'dst_header';

    # like(
    #     capture_stdout {
    #         dies { $trafo->job_info_input_file }
    #     }, qr/$tr_input/,
    #     'Should have error for missing input file option or configuration'
    # );

    # like(
    #     capture_stdout {
    #         dies { $trafo->job_info_output_file }
    #     },
    #     qr/$tr_output/,
    #     'Should have error for missing output file option or configuration'
    # );

    # like( capture_stdout { $trafo->job_info_work },
    #     qr/$tr_workin/ms, 'job_intro should work');

    # like( capture_stdout { $trafo->job_summary },
    #     qr/$tr_summar/ms, 'job_summary should work');


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
        f_date => '21.08.2018',
        f_int  => -2300125,
        f_num  => 51720.100,
        f_sint => 2301,
        f_text => 'A long long, not so long text text',
        f_stmp => '2014-01-31T18:30:34:000',
        f_vchr => 'a variable character type',
    };

    my $record = $trafo->column_type_trafos( $original_record, 'logstr' );

    is $record, $expected_record, 'test column_type_trafos';

    my @expected_meths = (
        qw{
            copy_nonzero
            join_fields
            lookup_in_dbtable
            lookup_in_ds
            move_filtered
            move_filtered_regex
            null_ifzero
            number_only
            split_field
      }
    );
    ok my $meths = $trafo->collect_recipe_methods, 'collect recipe methods';
    is $meths, \@expected_meths, 'recipe methods (plugin methods)';

    # like(
    #     dies { $trafo->reader->contents_iter },
    #     qr/(database|server)( .+)? not (found|available)/,
    #     'Should have error for missing database'
    # );
    # TODO: other subtest for this:
    # try_ok {$trafo->transfer_db2db} 'transfer file to file';
    # header_map
};

subtest 'transform: column_trafos' => sub {
    my $input_options  = { input_file  => path(qw(t siruta.csv)) };
    my $output_options = { output_file => $output };
    my $recipe_file    = path(qw(t recipes table recipe-5.conf));
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    my $bag1 = bag { item 'id'; item 'denumire'; end; };
    my $bag2 = bag { item 'ident'; item 'name'; end; };

    ok my @shr = $trafo->recipe->table->src_header_raw, 'got the src raw header';
    is \@shr, $bag2, 'source raw header';
    is $trafo->recipe->table->src_header, $bag2, 'source header';
    is $trafo->recipe->table->dst_header, $bag1, 'destination header';
    my $header_map = { ident => 'id', name => 'denumire' };
    is $trafo->recipe->table->header_map, $header_map, 'header map';

    is $trafo->get_logfield_name, '?', 'default log field name';

    my $merged;
    like(
        $merged = capture_merged { $trafo->validate_file_src },
        qr/$tr_input/,
        'transfer file to file'
    );
    diag $merged if $ENV{TRANSFER_DEBUG};
    like(
        $merged = capture_merged { $trafo->validate_file_dst },
        qr/$tr_output/,
        'transfer file to file'
    );
    diag $merged if $ENV{TRANSFER_DEBUG};

    ok my $trafo_fields = $trafo->collect_recipe_fields, 'collect recipe fields';
    is $trafo_fields, ['denumire'], 'recipe trafo fileds';

    my $record = {
        id       => 100,
        denumire => 'a text     with   many    spaces',
    };
    my $expected = {
        id       => 100,
        denumire => 'a text with many spaces',
    };
    my $r = $trafo->column_trafos( $record, 'logstr' );
    is $r, $expected, 'the record is like expected';
};

subtest 'transform: column_trafos exception' => sub {
    my $input_options  = { input_file  => path(qw(t siruta.csv)) };
    my $output_options = { output_file => $output };
    my $recipe_file    = path(qw(t recipes table recipe-6.conf));
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    ok my $trafo_fields = $trafo->collect_recipe_fields, 'collect recipe fields';
    is $trafo_fields, ['valid'], 'recipe trafo fileds';

    like(
        dies { $trafo->validate_dst_file_fields },
        qr/\QDestination fields/,
        'Should have error for dst fields missmatch'
    );

    ok my $meths = $trafo->collect_recipe_methods, 'collect recipe methods';
    is $meths, ['first_upper'], 'recipe methods (plugin methods)';
};

# #--- Validations

# <source>
#   reader              = csv
#   file                = test-file.csv
# </source>
subtest 'validate file src - wrong input file from the recipe' => sub {
    my $recipe_file  = path(qw(t recipes table recipe-5.conf));
    my $trafo_params = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => {},
        output_options => {},
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    is $trafo->get_logfield_name, '?', 'default log field name';

    my $msg = __("Invalid input file specified; use '--if' or fix the source file in the recipe.");
    like(
        dies { $trafo->validate_file_src },
        qr/$msg/,
        'validate input: wrong input from the recipe'
    );
};

# <source>
#   reader              = dbf
#   file                =
# </source>
subtest 'validate file src - no input file from the recipe' => sub {
    my $recipe_file  = path(qw(t recipes recipe-dbf2.conf));
    my $trafo_params = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => {},
        output_options => {},
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    my $msg = __("No input file specified; use '--if' or set the source file in the recipe.");
    like(
        dies { $trafo->validate_file_src },
        qr/$msg/,
        'validate input: no input from the recipe'
    );
};

# <destination>
#   writer              = csv
#   file                = t/nonexistentoutput/test-file.csv
# </destination>
subtest 'validate file dst - wrong output path from file name in the recipe' => sub {
    my $recipe_file  = path(qw(t recipes table recipe-5.conf));
    my $trafo_params = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => {},
        output_options => {},
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    my $msg = __("Invalid output file specified; use '--of' or fix the destination file in the recipe.");
    like(
        dies { $trafo->validate_file_dst },
        qr/$msg/,
        'validate output: no output from the recipe'
    );
};

# TODO: decide how to handle file and path configs in the recipe
# <destination>
#   writer              = csv
#   file                = test-file.csv
#   path                = t/nonexistentoutput
# </destination>
subtest 'validate file dst - wrong output path from the recipe' => sub {
    my $recipe_file  = path(qw(t recipes recipe-6.conf));
    my $trafo_params = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => {},
        output_options => {},
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    my $msg = __("Invalid output path specified; fix the destination path in the recipe.");
    like(
        dies { $trafo->validate_file_dst },
        qr/$msg/,
        'validate output: no output from the recipe'
    );
};

#  <destination>
#   writer              = dbf
#   file                =
# </destination>
subtest 'validate file dst - no output file from the recipe' => sub {
    my $recipe_file  = path(qw(t recipes recipe-dbf3.conf));
    my $trafo_params = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => {},
        output_options => {},
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';

    my $msg = __("No output file specified; use '--of' or set the destination file in the recipe.");
    like(
        dies { $trafo->validate_file_dst },
        qr/$msg/,
        'validate output: no output from the recipe'
    );
};

# <source>
#   reader              = fake_db
#   target              = test
#   table               = test_db
# </source>
subtest 'validate db src - wrong ... from the recipe' => sub {
    my $uri            = 'db:pg://@localhost/nonexistent';
    my $recipe_file    = path( 't', 'recipes', 'recipe-fake_db.conf' );
    my $input_options  = { input_uri  => $uri };
    my $output_options = { output_uri => $uri };
    my $trafo_params   = [ recipe_file => $recipe_file ];

    my $transfer = App::Transfer->new;
    isa_ok $transfer, ['App::Transfer'], 'transfer instance';
    ok my $trafo = App::Transfer::Transform->new(
        transfer       => $transfer,
        input_options  => $input_options,
        output_options => $output_options,
        @{$trafo_params},
    ), 'new trafo instance';
    isa_ok $trafo, ['App::Transfer::Transform'], 'transform instance';
    isa_ok $trafo->recipe, ['App::Transfer::Recipe'], 'transfer recipe instance';

    # $trafo->validate_db_src;

    # my $msg = __("Invalid input.");
    # like(
    #     dies { $trafo->validate_db_src },
    #     qr/$msg/,
    #     'validate input: wrong input from the recipe'
    # );
};

unlink $output or warn "unlink output $output: $!";

done_testing;
