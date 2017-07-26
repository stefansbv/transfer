use 5.010;
use strict;
use warnings;
use Path::Tiny;
use Test::Most;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::Recipe;

#-- Invalid recipes

# Is hard to get an exception from Config::General, it's happy even with
# text documents...
subtest 'Not a conf file' => sub {
    my $recipe_file = path( 't', 'recipes', 'not_a_recipe.ini' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->recipe_data }  'App::Transfer::X',
        'Should get an exception - not a recipe file';
};

subtest 'Not a recipe file' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-not_a_recipe.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->header }  'App::Transfer::X',
        'Should get an exception for missing recipe section';
};

subtest 'Recipe header only' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-header.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->header }  'App::Transfer::X',
        'Should get an exception for missing recipe config section';
};

subtest 'Recipe header + config' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-config.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->source }  'App::Transfer::X',
        'Should get an exception for missing recipe tables section';
    throws_ok { $recipe->destination }  'App::Transfer::X',
        'Should get an exception for missing recipe tables section';
};

subtest 'Recipe syntax version' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-wrongversion.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->header }  'App::Transfer::X',
        'Should get an exception for wrong syntax version';

    $recipe_file = path( 't', 'recipes', 'recipe-noversion.conf' );
    ok $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    throws_ok { $recipe->header }  'App::Transfer::X',
        'Should get an exception for wrong syntax version';
};

#-- Minimum valid recipe

subtest 'Recipe - minimum' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-min.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    lives_ok { $recipe->header } 'Should get the header section';
    lives_ok { $recipe->source } 'Should get the config source section';
    lives_ok { $recipe->destination } 'Should get the config destination section';

    # Header
    is $recipe->header->version, 1, 'recipe version';
    is $recipe->header->syntaxversion, 1, 'syntax version';
    is $recipe->header->name, 'Test recipe', 'recipe name';
    is $recipe->header->description, 'Does this and that...', 'description';

    # Config
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src', 'recipe source';
    is $recipe->source->reader, 'xls', 'has reader xls';
    is $recipe->source->file, 't/siruta.xls', 'has a file';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst', 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
    is $recipe->get_uri('siruta'), 'db:firebird://localhost/siruta', 'target URI';

    # Tables
    foreach my $name ( $recipe->tables->all_table_names ) {
        is $recipe->tables->has_table($name), $name, "has table name '$name'";
        ok my $recipe_table = $recipe->tables->get_table($name), 'table.';
        ok $recipe_table->description, 'table desc.';
        ok defined $recipe_table->skiprows, 'table skip rows';
        ok $recipe_table->logfield, 'log field name';
        is ref $recipe_table->orderby, '', 'table orderby';
        is ref $recipe_table->headermap, 'HASH', 'headermap';
    }
};

#-- Config section

subtest 'Config section: from xls to db' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src', 'recipe source';
    is $recipe->source->reader, 'xls', 'has reader xls';
    is $recipe->source->file, 't/siruta.xls', 'has a file';
    is $recipe->source->target, undef, 'has no target';
    is $recipe->source->table, undef, 'has no table';
    is $recipe->source->date_format, 'dmy', 'has date format';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst', 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->file, undef, 'has no file';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
};

subtest 'Config section: from xls to db - no file' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe4options-2.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst', 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
};

subtest 'Config section: from db to xls' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe4options-1.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src', 'recipe source';
    is $recipe->source->reader, 'db', 'has reader';
    is $recipe->source->target, 'siruta', 'has target';
    is $recipe->source->table, 'siruta', 'has table';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst', 'recipe destination';
    is $recipe->destination->writer, 'csv', 'has writer';
    is $recipe->destination->file, 't/siruta.csv', 'has a file';
};

subtest 'Config section: from db to csv' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe4options-1.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src', 'recipesource';
    is $recipe->source->reader, 'db', 'has reader';
    is $recipe->source->target, 'siruta', 'has target';
    is $recipe->source->table, 'siruta', 'has table';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst', 'recipe destination';
    is $recipe->destination->writer, 'csv', 'has writer';
    is $recipe->destination->file, 't/siruta.csv', 'has a file';
};

#-- Tables section

my $hmap = { id => 'id', denumire => 'denumire' };

subtest 'Table section minimum config' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-table-0.conf' );
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
    my $recipe_file = path( 't', 'recipes', 'recipe-table-1.conf' );
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    is $recipe->tables->has_table('test_table'), 'test_table', 'has table name';
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

    # Columns
    my $info = {
        denumire => {
            length => 10,
            name   => "denumire",
            pos    => 2,
            prec   => "",
            scale  => "",
            type   => "varchar",
        },
        id => {
            length => 2,
            name   => "id",
            pos    => 1,
            prec   => "",
            scale  => "",
            type   => "integer"
        },
    };
    ok my $cols = $recipe_table->columns, 'get columns list';
    cmp_deeply $cols, $info, 'columns info';
};

subtest 'Table section medium config' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe-table-2.conf' );
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
    my $recipe_file = path( 't', 'recipes', 'recipe-table-3.conf' );
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

#-- Transform

### XXX Setting a COPY without a REPLACENULL attribute for a row trafo
### makes this subtest fail instead of the following... ?!
subtest 'Column transformation type' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $trafos_col = $recipe->transform->column, 'column trafos';
    my $fields  = [qw(codp)];
    my $methods = [[qw(number_only null_ifzero)]];
    my $idx     = 0;
    foreach my $step ( @{$trafos_col} ) {
        my $field  = $fields->[$idx];
        my $method = $methods->[$idx];
        ok $step->can('field'), 'the step has field';
        ok $step->can('method'), 'the step has methods';
        is $step->field, $field, qq(the field is $field');
        cmp_deeply $step->method, $method, qq(the methods: "@$method");
        $idx++;
    }
};

subtest 'Row transformation type' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $trafos_row = $recipe->transform->row, 'row trafos';

    # Expected result in the recipe order
    my $expected_lookupdb = [
        {   field_src     => 'denumire',
            field_src_map => { denumire => 'localitate' },
            method        => 'lookup_in_dbtable',
            field_dst     => [ 'denloc', 'cod' ],
            table         => 'test_dict',
            hints         => 'localitati',
            fields        => ['localitate', 'siruta'],
            where_fld     => 'localitate',
        },
        {   field_src     => 'denumire',
            field_src_map => { denumire => 'localitate' },
            method        => 'lookup_in_dbtable',
            field_dst     => [ 'denloc', 'cod' ],
            table         => 'test_dict',
            hints         => 'localitati',
            fields        => ['localitate', 'siruta'],
            where_fld     => 'localitate',
        },
        {   field_src     => 'denumire',
            field_src_map => { denumire => 'localitate' },
            method        => 'lookup_in_dbtable',
            field_dst     => [ 'denloc', 'siruta' ],
            table         => 'test_dict',
            hints         => 'localitati',
            fields        => ['localitate', 'siruta'],
            where_fld     => 'localitate',
        },
        {   field_src     => 'localitate',
            field_src_map => 'localitate',
            method        => 'lookup_in_dbtable',
            field_dst     => ['siruta'],
            table         => 'test_dict',
            hints         => undef,
            fields        => ['siruta'],
            where_fld     => 'localitate',
        },
    ];

    foreach my $step ( @{$trafos_row} ) {
        ok my $type = $step->type, 'step type';
        ok my $field_src = $step->field_src,  'src field(s)';
        ok my $field_dst = $step->field_dst,  'dst field(s)';
        ok my $method    = $step->method,     'method(s)';
        if ($type eq 'split') {
            ok $step->can('separator'), 'split separator';
            is ref $field_src, '', 'split src field string';
            is ref $field_dst, 'ARRAY', 'split dst fields array';
        }
        if ($type eq 'join') {
            ok $step->can('separator'), 'join separator';
            is ref $field_src, 'ARRAY', 'join src fields array';
            is ref $field_dst, '', 'join dst field string';
        }
        if ($type eq 'copy') {
            is ref $field_src, '', 'copy src field string';
            is ref $field_dst, '', 'copy dst field string';
            is $step->datasource, 'status', 'copy datasource';
        }
        if ($type eq 'lookup') {
            is $step->method, 'lookup_in_ds', 'lookup method';
            is $field_src, 'category', 'lookup src field string';
            is $field_dst, 'categ_code', 'lookup dst field array';
            is $step->datasource, 'category', 'lookup datasource';
        }
        if ( $type eq 'lookupdb' ) {
            my $expected = shift @{$expected_lookupdb};
            is $field_src, $expected->{field_src},
                'lookupdb src field string';
            cmp_bag $field_dst, $expected->{field_dst},
                'lookupdb dst fields array';
            is $step->table, $expected->{table},
                'lookupdb datasource table';
            is $step->hints, $expected->{hints}, 'lookupdb hints';
            cmp_deeply $step->field_src_map, $expected->{field_src_map},
                'source field mapping';
            cmp_bag $step->fields, $expected->{fields},
                'lookup fields list';
            is $step->where_fld, $expected->{where_fld},
                'lookupdb where field';
        }
    }
};

#-- Datasource

subtest 'Datasources' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe.conf' );
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    is ref $recipe->datasource->get_valid_list('two_elements'), 'ARRAY',
        'Two valid elements list';
    is ref $recipe->datasource->get_valid_list('one_element'), 'ARRAY',
        'One valid element list';
    is ref $recipe->datasource->get_non_valid_list('two_elements'), 'ARRAY',
        'Two invalid elements list';
    is ref $recipe->datasource->get_non_valid_list('one_element'), 'ARRAY',
        'One invalid elements list';

    # XXX Test thoroughly; fix module
    # Passes on wrong input, example:
    # <hints localitati>
    #   <record>
    #     item              = Izvorul Mures
    #     hint              = Izvoru Mureșului
    #   <record>
    #   </record>
    #     item              = Sfantu Gheorghe
    #     hint              = Sfîntu Gheorghe
    #   <record>
    #   </record>
    #     item              = Podu Olt
    #     hint              = Podu Oltului
    #   <record>
    #   </record>
    #     item              = Baile Tusnad
    #     hint              = Băile Tușnad
    #   </record>
    # </hints>
    is ref $recipe->datasource->get_hints('one_element'), 'HASH',
        'One element hint dictionary';
    is ref $recipe->datasource->get_hints('two_elements'), 'HASH',
        'Two elements hint dictionary';

    is ref $recipe->datasource->get_ds('one_element'), 'ARRAY',
        'One element ds dictionary';
    is ref $recipe->datasource->get_ds('two_elements'), 'ARRAY',
        'Two elements ds dictionary';
};

done_testing;
