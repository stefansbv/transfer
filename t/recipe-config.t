use 5.010;
use strict;
use warnings;

use Path::Tiny;
use Test::Most;

use App::Transfer::Recipe;

subtest 'Config section: from excel to db' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe.conf' ), "the recipe file";
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src';
    is $recipe->source->reader, 'excel', 'has reader excel';
    is $recipe->source->file, 't/siruta.xls', 'has a file';
    is $recipe->source->target, undef, 'has no target';
    is $recipe->source->table, undef, 'has no table';
    is $recipe->source->date_format, 'dmy', 'has date format';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->file, undef, 'has no file';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
};

subtest 'Config section: from excel to db - no file' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe4options-2.conf' ), "the recipe file";
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
};

subtest 'Config section: missing' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe4options-0.conf' ), "the recipe file";
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->source }
    qr/\QThe recipe must have a 'config'/,
    'Should get an exception for missing config source subsection';
    throws_ok { $recipe->destination }
    qr/\QThe recipe must have a 'config'/,
    'Should get an exception for missing config destination subsection';
    throws_ok { $recipe->in_type }
    qr/\QThe recipe must have a 'config'/,
    'Should get an exception for missing config source subsection';
    throws_ok { $recipe->out_type }
    qr/\QThe recipe must have a 'config'/,
    'Should get an exception for missing config destination subsection';
};

subtest 'Config section: from db to excel' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe4options-1.conf' ), "the recipe file";
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src';
    is $recipe->source->reader, 'db', 'has reader';
    is $recipe->source->target, 'siruta', 'has target';
    is $recipe->source->table, 'siruta', 'has table';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst';
    is $recipe->destination->writer, 'csv', 'has writer';
    is $recipe->destination->file, 't/siruta.csv', 'has a file';
};

done_testing;
