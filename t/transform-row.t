use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use Locale::TextDomain qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

use App::Transfer;
use App::Transfer::Transform;
use App::Transfer::Recipe::Transform::Row::Join;
use App::Transfer::Recipe::Transform::Row::Split;
use App::Transfer::Recipe::Transform::Row::Copy;
use App::Transfer::Recipe::Transform::Row::Batch;
use lib 't/lib';

binmode STDOUT, ':utf8';

use Capture::Tiny 0.12 qw(capture_stdout capture_merged);

$ENV{TRANSFER_LOG_CONFIG} = 't/log.conf';

my $uri            = 'db:firebird://@localhost/dbpath';
my $recipe_file    = path( 't', 'recipes', 'recipe-db2db.conf' );
my $trafo_params   = [ recipe_file => $recipe_file ];
my $input_options  = { input_uri  => $uri };
my $output_options = { output_uri => $uri };

my $trans1 = __('Input:');

my $transfer = App::Transfer->new;
ok my $trafo = App::Transfer::Transform->new(
    transfer       => $transfer,
    input_options  => $input_options,
    output_options => $output_options,
    @{$trafo_params},
    ), 'new trafo instance';

#-- Join

subtest 'join - src fields included in dst' => sub {
    my $step = App::Transfer::Recipe::Transform::Row::Join->new(
        type      => 'join',
        separator => ", ",
        field_src => [qw{localitate strada numarul}],
        method    => 'join_fields',
        field_dst => 'adresa',
    );
    isa_ok $step, ['App::Transfer::Recipe::Transform::Row::Join'], 'join step';

    my $logstr = 'test-transform';
    my $record = {
        id         => 1,
        localitate => "Izvorul Mures",
        numarul    => "nr. 5",
        strada     => "str. Brasovului",
    };
    my $expected = {
        id         => 1,
        localitate => "Izvorul Mures",
        numarul    => "nr. 5",
        strada     => "str. Brasovului",
        adresa     => "Izvorul Mures, str. Brasovului, nr. 5",
    };

    is $trafo->type_join( $step, $record, $logstr ), $expected, 'join';
};

#- Split

subtest 'split - src fields included in dst' => sub {
    my $step = App::Transfer::Recipe::Transform::Row::Split->new(
        type      => 'split',
        separator => ",",
        field_src => 'adresa',
        method    => 'split_field',
        field_dst => [qw{localitate strada numarul}],
    );
    isa_ok $step, ['App::Transfer::Recipe::Transform::Row::Split'], 'split step';

    my $logstr = 'test-transform';
    my $record = {
        id         => 1,
        adresa     => "Izvorul Mures, str. Brasovului, nr. 5",
    };
    my $expected = {
        id         => 1,
        localitate => "Izvorul Mures",
        numarul    => "nr. 5",
        strada     => "str. Brasovului",
        adresa     => "Izvorul Mures, str. Brasovului, nr. 5",
    };

    is $trafo->type_split( $step, $record, $logstr ), $expected, 'split';
};

#--- Copy

subtest 'copy - src fields to dst: copy, no required attribs' => sub {
    is(
        dies {
            App::Transfer::Recipe::Transform::Row::Copy->new({
                type       => 'copy',
                field_src  => 'status',
                method     => 'move_filtered',
                field_dst  => 'obs',
                attributes => { COPY => 1 },
            });
        },
        "For the 'copy' step, one of the attributes: REPLACE, REPLACENULL, APPEND or APPENDSRC is required!\n",
        'Should have error for missing attributes for copy'
    );
};

subtest 'copy - src fields to dst: move || copy && attribs' => sub {
    for my $spec (
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { MOVE => 1, REPLACE => 1 },
            {   id     => 1,
                status => undef,
                obs    => 'unknown',
            },
            'copy: replace, move',
        ],
        [   {   id     => 1,
                status => "unknown",
                obs    => 'an observation',
            },
            { COPY => 1, REPLACE => 1 },
            {   id     => 1,
                status => 'unknown',
                obs    => 'unknown',
            },
            'copy: replace, copy',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { MOVE => 1, REPLACENULL => 1 },
            {   id     => 1,
                status => undef,
                obs    => 'an observation',
            },
            'copy: replacenull, move (obs not null)',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { COPY => 1, REPLACENULL => 1 },
            {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            'copy: replacenull, copy (obs not null)',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => undef,
            },
            { MOVE => 1, REPLACENULL => 1 },
            {   id     => 1,
                status => undef,
                obs    => 'unknown',
            },
            'copy: replacenull, move (obs is null)',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => undef,
            },
            { COPY => 1, REPLACENULL => 1 },
            {   id     => 1,
                status => 'unknown',
                obs    => 'unknown',
            },
            'copy: replacenull, copy (obs is null)',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { COPY => 1, APPEND => 1 },
            {   id     => 1,
                status => 'unknown',
                obs    => 'an observation, unknown',
            },
            'copy: append, copy',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { MOVE => 1, APPEND => 1 },
            {   id     => 1,
                status => undef,
                obs    => 'an observation, unknown',
            },
            'copy: append, move',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { MOVE => 1, APPENDSRC => 1 },
            {   id     => 1,
                status => undef,
                obs    => 'an observation, status: unknown',
            },
            'copy: appendsrc, move',
        ],
        [   {   id     => 1,
                status => 'unknown',
                obs    => 'an observation',
            },
            { COPY => 1, APPENDSRC => 1 },
            {   id     => 1,
                status => "unknown",
                obs    => 'an observation, status: unknown',
            },
            'copy: appendsrc, copy',
        ],

    ) {
        my $step = App::Transfer::Recipe::Transform::Row::Copy->new({
            type       => 'copy',
            field_src  => 'status',
            method     => 'move_filtered',
            field_dst  => 'obs',
            attributes => $spec->[1],
        });
        isa_ok $step, ['App::Transfer::Recipe::Transform::Row::Copy'], "step: $spec->[3]";
        is $trafo->type_copy( $step, $spec->[0], 'logstr' ), $spec->[2], $spec->[3];
    }
};

# TODO: test Batch

done_testing;
