use strict;
use warnings;
use 5.010;
use utf8;
use Test::Most;
use Path::Tiny;
use Locale::TextDomain qw(App-Transfer);

use App::Transfer;
use App::Transfer::Transform;
use App::Transfer::Recipe::Transform::Row::Join;
use lib 't/lib';

binmode STDOUT, ':utf8';

my $uri            = 'db:firebird://@localhost/dbpath';
my $target_params  = [ uri => $uri ];
my $recipe_file    = path( 't', 'recipes', 'recipe-db.conf' );
my $trafo_params   = [ recipe_file => $recipe_file ];
my $input_options  = { input_uri  => $target_params };
my $output_options = { output_uri => $target_params };

my $transfer = App::Transfer->new;
ok my $trafo = App::Transfer::Transform->new(
    transfer       => $transfer,
    input_options  => $input_options,
    output_options => $output_options,
    @{$trafo_params},
    ), 'new trafo instance';

throws_ok { $trafo->job_info_input_file }
    'App::Transfer::X',
    'Should have error for missing file option or configuration';

throws_ok { $trafo->job_info_output_file }
    'App::Transfer::X',
    'Should have error for missing file option or configuration';

subtest 'join - src fields included in dst' => sub {
    my $step = App::Transfer::Recipe::Transform::Row::Join->new(
        type      => 'join',
        separator => ", ",
        field_src => [qw{localitate strada numarul}],
        method    => 'join_fields',
        field_dst => 'adresa',
    );
    isa_ok $step, 'App::Transfer::Recipe::Transform::Row::Join', 'join step';

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

    cmp_deeply $trafo->type_join( $step, $record, $logstr ), $expected, 'join';
};

# subtest 'join - src fields missing from dst' => sub {
#     my $step = App::Transfer::Recipe::Transform::Row::Join->new(
#         type      => 'join',
#         separator => ", ",
#         field_src => [qw{localitate strada numarul}],
#         method    => 'join_fields',
#         field_dst => 'adresa',
#     );
#     isa_ok $step, 'App::Transfer::Recipe::Transform::Row::Join', 'join step';

#     my $logstr = 'test-transform';
#     my $record = {
#         id         => 1,
#         localitate => "Izvorul Mures",
#         numarul    => "nr. 5",
#         strada     => "str. Brasovului",
#     };
#     my $expected = {
#         id     => 1,
#         adresa => "Izvorul Mures, str. Brasovului, nr. 5",
#     };

#     cmp_deeply $trafo->type_join( $step, $record, $logstr ), $expected, 'join';
# };

done_testing;
