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
use lib 't/lib';

binmode STDOUT, ':utf8';

my $uri            = 'db:firebird://@localhost/dbpath';
my $recipe_file    = path( 't', 'recipes', 'recipe-db2db.conf' );
my $trafo_params   = [ recipe_file => $recipe_file ];
my $input_options  = { input_uri  => $uri };
my $output_options = { output_uri => $uri };

my $transfer = App::Transfer->new;
ok my $trafo = App::Transfer::Transform->new(
    transfer       => $transfer,
    input_options  => $input_options,
    output_options => $output_options,
    @{$trafo_params},
    ), 'new trafo instance';

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

done_testing;
