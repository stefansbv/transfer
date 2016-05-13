#
# Test the 'tables' section of the recipe
##
use 5.010001;
use strict;
use warnings;
use Path::Class;
use Test::More;

use App::Transfer::Recipe;

my $hmap = { id => 'id', denumire => 'denumire' };

subtest 'Table section minimum config' => sub {
    ok my $recipe_file = file( 't', 'recipes', 'recipe-table-0.conf' ),
        "the recipe file";
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok my $table = $recipe->tables->has_table('test_table'), 'has table name';
    ok my $recipe_table = $recipe->tables->get_table('test_table'), 'table.';
    ok $recipe_table->description, 'table desc.';
    ok $recipe_table->logfield, 'log field name';
    is_deeply $recipe_table->headermap, $hmap,  'headermap';
};

subtest 'Table section maximum config' => sub {
    ok my $recipe_file = file( 't', 'recipes', 'recipe-table-1.conf' ),
        "the recipe file";
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok my $table = $recipe->tables->has_table('test_table'), 'has table name';
    ok my $recipe_table = $recipe->tables->get_table('test_table'), 'table.';
    ok $recipe_table->description, 'table desc.';
    ok defined $recipe_table->skiprows, 'table skip rows';
    ok $recipe_table->logfield, 'log field name';
    is_deeply $recipe_table->orderby, [qw(id denumire)], 'table orderby';
    my $expected = {
        status => { "!" => "= completed", "-not_like" => "pending%" },
        user   => undef,
    };
    is_deeply $recipe_table->filter, $expected, 'table filter';
    is_deeply $recipe_table->headermap, $hmap, 'headermap';
    is_deeply $recipe_table->tempfield, [ 'seria', 'factura' ], 'tempfields';
};

subtest 'Table section medium config' => sub {
    ok my $recipe_file = file( 't', 'recipes', 'recipe-table-2.conf' ),
        "the recipe file";
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok my $table = $recipe->tables->has_table('test_table'), 'has table name';
    ok my $recipe_table = $recipe->tables->get_table('test_table'), 'table.';
    ok $recipe_table->description, 'table desc.';
    ok defined $recipe_table->skiprows, 'table skip rows';
    ok $recipe_table->logfield, 'log field name';
    is_deeply $recipe_table->orderby, { -asc => 'denumire' }, 'table orderby';
    is_deeply $recipe_table->headermap, $hmap,  'headermap';
    is_deeply $recipe_table->tempfield, [ 'seria' ], 'tempfields';
};

subtest 'Table section complex orderby config' => sub {
    ok my $recipe_file = file( 't', 'recipes', 'recipe-table-3.conf' ),
        "the recipe file";
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok my $table = $recipe->tables->has_table('test_table'), 'has table name';
    ok my $recipe_table = $recipe->tables->get_table('test_table'), 'table.';
    ok $recipe_table->description, 'table desc.';
    ok defined $recipe_table->skiprows, 'table skip rows';
    ok $recipe_table->logfield, 'log field name';
    is_deeply $recipe_table->orderby, [
        { -asc  => "colA" },
        { -desc => "colB" },
        { -asc  => [ "colC", "colD" ] },
    ], 'table orderby';
    is $recipe_table->get_plugin('date'), 'date_german', 'plugin for date';
    is_deeply $recipe_table->headermap, $hmap, 'headermap';
};

done_testing;
