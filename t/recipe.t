use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use Locale::TextDomain qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

use App::Transfer::Recipe;

my $trans1 = __ "The recipe must have a 'recipe' section.";
my $trans2 = __ "The recipe must have a valid 'syntaxversion' attribute (the current version is 2)";
my $trans3 = __ "The recipe must have a 'table' section.";
my $trans4 = __x("The v{sv} recipe table section must have a 'header' attribute instead of 'headermap'", sv => 2);

my $bag1 = bag { item 'id'; item 'denumire'; end; };

#-- Invalid recipes

# Is hard to get an exception from Config::General, it's happy even with
# text documents...
subtest 'Not a conf file' => sub {
    my $recipe_file = path(qw(t recipes invalid not_a_recipe.ini));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/$trans1/,
        'Should get an exception - not a valid recipe file'
    );
};

subtest 'Not a recipe file' => sub {
    my $recipe_file = path(qw(t recipes invalid recipe-not_a_recipe.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/$trans1/,
        'Should get an exception - not a valid recipe file'
    );
};

subtest 'Recipe header only' => sub {
    my $recipe_file = path(qw(t recipes invalid recipe-header.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/\Q$trans2/sm,
        'Should get an exception - not a valid recipe file'
    );
};

subtest 'Recipe header + config' => sub {
    my $recipe_file = path(qw(t recipes invalid recipe-config.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/\Q$trans2/sm,
        'Should get an exception - not a valid recipe file'
    );
};

subtest 'Recipe syntax version' => sub {
    my $recipe_file = path(qw(t recipes versions recipe-wrongversion.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/\Q$trans2/sm,
        'Should get an exception - not a valid recipe file'
    );

    $recipe_file = path(qw(t recipes versions recipe-noversion.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/\Q$trans2/sm,
        'Should get an exception - not a valid recipe file'
    );
};

subtest 'Recipe syntax version 1 sections' => sub {
    my $recipe_file = path(qw(t recipes versions recipe-tables_headermap.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/$trans3/,
        'Should get an exception - not a valid recipe file'
    );

    $recipe_file = path(qw(t recipes versions recipe-table_headermap.conf));
    like(
        dies {
            App::Transfer::Recipe->new(
                recipe_file => $recipe_file->stringify )
          },
        qr/$trans4/,
        'Should get an exception - not a valid recipe file'
    );
};

#-- Minimum valid recipe

subtest 'Recipe - minimum' => sub {
    my $recipe_file = path(qw(t recipes recipe-min.conf));
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    is $recipe->header, D(), 'Should get the header section';
    is $recipe->source, D(), 'Should get the config source section';
    is $recipe->destination, D(), 'Should get the config destination section';

    # Header
    is $recipe->header->version, 1, 'recipe version';
    is $recipe->header->syntaxversion, 2, 'syntax version';
    is $recipe->header->name, 'Test recipe', 'recipe name';
    is $recipe->header->description, 'Does this and that...', 'description';

    # Config
    isa_ok $recipe->source, ['App::Transfer::Recipe::Src'], 'recipe source';
    is $recipe->source->reader, 'xls', 'has reader xls';
    is $recipe->source->file, 't/siruta.xls', 'has a file';
    isa_ok $recipe->destination, ['App::Transfer::Recipe::Dst'], 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';
    is $recipe->get_uri('siruta'), 'db:firebird://localhost/siruta', 'target URI';

    # Table
    ok my $table = $recipe->table, 'table object instance';
    is $table->logfield, 'siruta', 'log field name';
    is $table->rectangle, ['A27','E36'], 'rectangle';
    is ref $table->orderby, '', 'table orderby';
    my $fields = [qw(siruta denloc codp)];
    is $table->src_header, $fields, 'source header';
    is $table->dst_header, $fields, 'destination header';
    my %h_map = map { $_ => $_ } @{$fields};
    is $table->header_map, \%h_map, 'header map';
};

#-- Config section

subtest 'Config section: from file2db - no file' => sub {
    my $recipe_file = path(qw(t recipes recipe-csv2db.conf));
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';

    # Source
    isa_ok $recipe->source, ['App::Transfer::Recipe::Src'], 'recipe source';
    is $recipe->source->reader, 'csv', 'has reader';
    is $recipe->source->file, '', 'has no file';

    # Destination
    isa_ok $recipe->destination, ['App::Transfer::Recipe::Dst'], 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'siruta', 'has target';
    is $recipe->destination->table, 'siruta', 'has table';

    # Target
    ok my ($name, $uri) = each %{ $recipe->target }, 'recipe target config';
    is $name, 'siruta', 'target name';
    is $uri, 'db:firebird://localhost/siruta', 'target uri';
};

subtest 'Config section: from db2db' => sub {
    my $recipe_file = path(qw(t recipes recipe-db2db.conf));
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';

    # Source
    isa_ok $recipe->source, ['App::Transfer::Recipe::Src'], 'recipe source';
    is $recipe->source->reader, 'db', 'has reader xls';
    is $recipe->source->file, '', 'has no file';
    is $recipe->source->target, 'target1', 'has target';
    is $recipe->source->table, 'test_db', 'has table';
    is $recipe->source->date_format, 'iso', 'has default date format';

    # Destination
    isa_ok $recipe->destination, ['App::Transfer::Recipe::Dst'], 'recipe destination';
    is $recipe->destination->writer, 'db', 'has writer db';
    is $recipe->destination->target, 'target2', 'has target';
    is $recipe->destination->table, 'test_db', 'has table';

    # Targets
    while (my ($name, $uri) = each (%{ $recipe->target })) {
        like $name, qr/target\d/, 'target name';
        like $uri, qr/hostname\d/, 'target uri';
    }
};

subtest 'Config section: from db2file' => sub {
    my $recipe_file = path(qw(t recipes recipe-db2csv.conf));
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    isa_ok $recipe->source, ['App::Transfer::Recipe::Src'], 'recipe source';
    is $recipe->source->reader, 'db', 'has reader';
    is $recipe->source->target, 'siruta', 'has target';
    is $recipe->source->table, 'siruta', 'has table';
    isa_ok $recipe->destination, ['App::Transfer::Recipe::Dst'], 'recipe destination';
    is $recipe->destination->writer, 'csv', 'has writer';
    is $recipe->destination->file, 't/siruta.csv', 'has a file';
};

#-- Tables section

my $header_aref = [qw{id denumire}];
my $header_href = { id => 'id', denumire => 'denumire' };

subtest 'Table section minimum config' => sub {
    my $recipe_file = path(qw(t recipes table recipe-0.conf));
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    is $recipe->table->logfield, 'id', 'log field name';
    is $recipe->table->src_header, $header_aref, 'source header';
    is $recipe->table->dst_header, $header_aref, 'destination header';
    is $recipe->table->header_map, $header_href, 'header map';
};

subtest 'Table section maximum config' => sub {
    my $recipe_file = path(qw(t recipes table recipe-1.conf));
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok $recipe->table->logfield, 'log field name';
    is $recipe->table->orderby, [qw(id denumire)], 'table orderby';
    my $expected = {
        status => { "!" => "= completed", "-not_like" => "pending%" },
        user   => undef,
    };
    is $recipe->table->filter, $expected, 'table filter';
    is $recipe->table->tempfield, [ 'seria', 'factura' ], 'tempfields';

    is $recipe->table->src_header, $bag1, 'source header';
    is $recipe->table->dst_header, $bag1, 'destination header';
    is $recipe->table->header_map, $header_href, 'header map';

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
    ok my $cols = $recipe->table->columns, 'get columns list';
    is $cols, $info, 'columns info';
};

subtest 'Table section medium config' => sub {
    my $recipe_file = path(qw(t recipes table recipe-2.conf));
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok $recipe->table->logfield, 'log field name';
    is $recipe->table->orderby, { -asc => 'denumire' }, 'table orderby';
    is $recipe->table->tempfield, [ 'seria' ], 'tempfields';

    is $recipe->table->src_header, $header_aref, 'source header';
    is $recipe->table->dst_header, $header_aref, 'destination header';
    is $recipe->table->header_map, $header_href, 'header map';
};

subtest 'Table section complex orderby config' => sub {
    my $recipe_file = path(qw(t recipes table recipe-3.conf));
    ok my $recipe
        = App::Transfer::Recipe->new( recipe_file => $recipe_file->stringify,
        ), 'new recipe instance';

    ok $recipe->table->logfield, 'log field name';
    is $recipe->table->orderby, [
        { -asc  => "colA" },
        { -desc => "colB" },
        { -asc  => [ "colC", "colD" ] },
    ], 'table orderby';
    is $recipe->table->get_plugin('date'), 'date_german', 'plugin for date';

    is $recipe->table->src_header, $header_aref, 'source header';
    is $recipe->table->dst_header, $header_aref, 'destination header';
    is $recipe->table->header_map, $header_href, 'header map';
};

#-- Transform section

subtest 'Column transformation type' => sub {
    my $recipe_file = path(qw(t recipes recipe.conf));
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
        is $step->method, $method, qq(the methods: "@$method");
        $idx++;
    }
};

subtest 'Row transformation type' => sub {
    my $recipe_file = path(qw(t recipes recipe.conf));
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $trafos_row = $recipe->transform->row, 'row trafos';

    my $bags_fdst = [
        bag { item 'cod'; item 'denloc'; end; },
        bag { item 'cod'; item 'denloc'; end; },
        bag { item 'siruta'; item 'denloc'; end; },
        bag { item 'siruta'; end; },
    ];

    my $bags_f = [
        bag { item 'localitate'; item 'siruta'; end; },
        bag { item 'localitate'; item 'siruta'; end; },
        bag { item 'localitate'; item 'siruta'; end; },
        bag { item 'siruta'; end; },
    ];

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
        my $bag_dst = shift @{$bags_fdst};
        my $bag_f   = shift @{$bags_f};

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
            is $step->valid_regex, '\d{4,4}', 'valid_regex';
            is $step->invalid_regex, '', 'invalid_regex';
        }
        if ($type eq 'lookup') {
            is $step->method, 'lookup_in_ds', 'lookup method';
            is $field_src, 'category', 'lookup src field string';
            is $field_dst, 'categ_code', 'lookup dst field array';
            is $step->datasource, 'category', 'lookup datasource';
        }
        if ( $type eq 'lookupdb' ) {
            my $expected = shift @{$expected_lookupdb};
            # dd $expected->{field_dst};
            is $field_src, $expected->{field_src},
                'lookupdb src field string';
            is $field_dst, $bag_dst, 'lookupdb dst fields array';
            is $step->table, $expected->{table},
                'lookupdb datasource table';
            is $step->hints, $expected->{hints}, 'lookupdb hints';
            is $step->field_src_map, $expected->{field_src_map},
                'source field mapping';
            # dd $expected->{fields};
            is $step->fields, $bag_f, 'lookup fields list';
            is $step->where_fld, $expected->{where_fld},
                'lookupdb where field';
        }
    }
};

#-- Datasource

subtest 'Datasources' => sub {
    my $recipe_file = path(qw(t recipes recipe.conf));
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

    is ref $recipe->datasource->get_ds('one_element'), 'ARRAY',
        'One element ds dictionary';
    is ref $recipe->datasource->get_ds('two_elements'), 'ARRAY',
        'Two elements ds dictionary';
};

done_testing;
