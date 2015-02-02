#!perl

use 5.010;
use strict;
use warnings;

use Path::Class;
use Test::More;

use App::Transfer;
use App::Transfer::Recipe;

ok my $recipe_file = file( 't', 'recipes', 'recipe.conf' ), "the recipe file";
ok my $recipe = App::Transfer::Recipe->new(
    recipe_file => $recipe_file->stringify,
), 'new recipe instance';

subtest 'Header section' => sub {
    is $recipe->header->version, 1, 'recipe version';
    is $recipe->header->syntaxversion, 2, 'syntax version';
    is $recipe->header->name, 'Test recipe', 'recipe name';
    is $recipe->header->description, 'Does this and that...', 'description';
};

subtest 'Config section' => sub {
    isa_ok $recipe->source, 'App::Transfer::Recipe::Src';
    is $recipe->source->reader, 'excel', 'has reader excel';
    is $recipe->source->file->stringify, 't/siruta.xls', 'has a file';
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
        ok $recipe->tables->get_table($table)->description, 'table desc.';
        ok defined $recipe->tables->get_table($table)->skiprows,
            'table skip rows';
        ok $recipe->tables->get_table($table)->primarykey,
            'table primary key';
        is ref $recipe->tables->get_table($table)->headermap, 'HASH',
            'headermap';
    }
};

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
        is_deeply $step->method, $method, qq(the methods: "@$method");
        $idx++;
    }
};

subtest 'Row transformation type' => sub {
    ok my $trafos_row = $recipe->transform->row, 'row trafos';
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
            is $step->datasource, '', 'copy datasource';
        }
        if ($type eq 'lookup') {
            is ref $field_src, '', 'lookup src field string';
            is ref $field_dst, '', 'lookup dst field string';
            is $step->datasource, 'one_element', 'lookup datasource';
        }
        if ($type eq 'lookup_db') {
            is ref $field_src, '',      'lookup_db src field string';
            is ref $field_dst, 'ARRAY', 'lookup_db dst fields array';
            is $step->datasource, 'two_elements', 'lookup_db datasource';
            ok $step->can('hints'), 'lookup_db hints';
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
