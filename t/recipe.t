use 5.010001;
use strict;
use warnings;

use Path::Tiny;
use Test::More;
use Test::Deep;

use App::Transfer;
use App::Transfer::Recipe;

ok my $recipe_file = path( 't', 'recipes', 'recipe.conf' ), "the recipe file";
ok my $recipe = App::Transfer::Recipe->new(
 recipe_file => $recipe_file->stringify,
), 'new recipe instance';

subtest 'Header section' => sub {
    is $recipe->header->version, 1, 'recipe version';
    is $recipe->header->syntaxversion, 1, 'syntax version';
    is $recipe->header->name, 'Test recipe', 'recipe name';
    is $recipe->header->description, 'Does this and that...', 'description';
};

subtest 'Config section' => sub {
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src';
    is $recipe->source->reader, 'excel', 'has reader excel';
    is $recipe->source->file, 't/siruta.xls', 'has a file';
    isa_ok $recipe->destination, 'App::Transfer::Recipe::Dst';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
    is $recipe->get_uri('siruta'), 'db:firebird://localhost/siruta', 'target URI';
};

subtest 'Header column map' => sub {
    foreach my $name ( $recipe->tables->all_table_names ) {
        ok my $table = $recipe->tables->has_table($name), 'has table name';
        is $table, $name, "got table name '$name'";
        ok my $recipe_table = $recipe->tables->get_table($table), 'table.';
        ok $recipe_table->description, 'table desc.';
        ok defined $recipe_table->skiprows, 'table skip rows';
        ok $recipe_table->logfield, 'log field name';
        is ref $recipe_table->orderby, '', 'table orderby';
        is ref $recipe_table->headermap, 'HASH', 'headermap';
    }
};

### XXX Setting a COPY withow a REPLACENULL attribute for a row trafo
### makes this subtest fail instead of the following... ?!
subtest 'Column transformation type' => sub {
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

subtest 'Datasources' => sub {
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
    #     <hints localitati>
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
