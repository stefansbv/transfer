use 5.010001;
use Path::Tiny;
use Test2::V0;
use Test2::Plugin::UTF8;

use App::Transfer::Recipe;

#-- Datasource

my $stare_ = [
    { "Foarte buna"    => "F" },
    { "foarte bun"     => "F" },
    { F                => "F" },
    { FB               => "F" },
    { Buna             => "B" },
    { buna             => "B" },
    { B                => "B" },
    { Satisfacatoare   => "S" },
    { Satisfacator     => "S" },
    { satisfacatoare   => "S" },
    { satisfacatoar    => "S" },
    { satisfacator     => "S" },
    { S                => "S" },
    { Nesatisfacatoare => "N" },
    { nesatisfacatoare => "N" },
    { Nesatisfacator   => "N" },
    { nesatisfacator   => "N" },
    { NS               => "N" },
    { N                => "N" },
];

subtest 'Datasources' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-ds.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';

    is ref $recipe->datasource->get_valid_list('stare_teh'), 'ARRAY',
        'Two valid elements list';

    ok my $stare = $recipe->datasource->get_ds('stare_teh'), 'get DS list';
    is ref $stare, 'ARRAY', 'stare datasource is ref';
    is $stare, $stare_, 'compare';

	isa_ok $recipe->datasource->hints, ['App::Transfer::Recipe::Hints'], 'check ISA';

    is $recipe->datasource->hints->get_hint_for(
        'localitati', 'Izvorul Mures'
	), 'Izvoru Mureșului', 'One element hint dictionary';

};

done_testing;
