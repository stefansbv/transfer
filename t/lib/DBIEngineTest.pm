package DBIEngineTest;

use 5.010;
use strict;
use warnings;
use utf8;
use Try::Tiny;
use Test::Most;
use Test::MockModule;
use Path::Class 0.33 qw(file dir);
use Locale::TextDomain qw(App-Transfer);
use Log::Log4perl;

use App::Transfer::Config;
use App::Transfer::Recipe::Transform;
use App::Transfer::Transform;
use App::Transfer::RowTrafos;

BEGIN { Log::Log4perl->init('t/log.conf') }

# Just die on warnings.
use Carp; BEGIN { $SIG{__WARN__} = \&Carp::confess }

use Data::Dump;

sub run {
    my ( $self, %p ) = @_;

    my $class           = $p{class};
    my @transfer_params = @{ $p{transfer_params} || [] };
    my $mock_transfer   = Test::MockModule->new('App::Transfer');

    can_ok $class, qw(
        get_info
        table_exists
    );

    subtest 'live database' => sub {
        my $transfer = App::Transfer->new(
            @transfer_params,
        );

        ok my $recipe = $transfer->recipe, 'get the recipe object';
        isa_ok $recipe, 'App::Transfer::Recipe', 'recipe';

        my $target = App::Transfer::Target->new(
            transfer => $transfer,
            @{ $p{target_params} || [] },
        );
        isa_ok $target, 'App::Transfer::Target', 'target';

        my $engine = $class->new(
            transfer => $transfer,
            target   => $target,
            @{ $p{engine_params} || [] },
        );
        if (my $code = $p{skip_unless}) {
            try {
                $code->( $engine ) || die 'NO';
            } catch {
                plan skip_all => sprintf(
                    'Unable to live-test %s engine: %s',
                    $class->name,
                    eval { $_->message } || $_
                );
            };
        }

        ok $engine, 'Engine instantiated';

        throws_ok { $engine->dbh->do('INSERT blah INTO __bar_____') } 'App::Transfer::X',
            'Database error should be converted to Transfer exception';
        is $@->ident, $class->key, 'Ident should be the engine';
        ok $@->message, 'The message should be from the translation';


        #######################################################################
        # Test the database connection, if appropriate.
        if ( my $code = $p{test_dbh} ) {
            $code->( $engine->dbh );
        }


        #######################################################################

        # Test begin_work() and finish_work().
        can_ok $engine, qw(begin_work finish_work);
        my $mock_dbh
            = Test::MockModule->new( ref $engine->dbh, no_auto => 1 );
        my $txn;
        $mock_dbh->mock( begin_work => sub { $txn = 1 } );
        $mock_dbh->mock( commit     => sub { $txn = 0 } );
        $mock_dbh->mock( rollback   => sub { $txn = -1 } );
        my @do;
        $mock_dbh->mock(
            do => sub {
                shift;
                @do = @_;
            }
        );
        ok $engine->begin_work, 'Begin work';
        is $txn, 1, 'Should have started a transaction';
        ok $engine->finish_work, 'Finish work';
        is $txn, 0, 'Should have committed a transaction';
        ok $engine->begin_work, 'Begin work again';
        is $txn, 1, 'Should have started another transaction';
        ok $engine->rollback_work, 'Rollback work';
        is $txn, -1, 'Should have rolled back a transaction';
        $mock_dbh->unmock('do');


        ######################################################################
        if ($class eq 'App::Transfer::Engine::pg') {
            # Test someting specific for Pg
        }


        ######################################################################
        # Test get_info

        my @fields_info = (
            [ 'field_01', 'char(1)' ],
            [ 'field_02', 'date' ],
            [ 'field_03', 'integer' ],
            [ 'field_04', 'numeric(9,3)' ],
            [ 'field_05', 'smallint' ],
            [ 'field_06', 'varchar(10)' ],
        );

        my $fields_list = join " \n , ", map { join ' ', @{$_} } @fields_info;
        my $table_info  = 'test_info';

        my $ddl = qq{CREATE TABLE $table_info ( \n   $fields_list \n);};

        ok $engine->dbh->do($ddl), "create '$table_info' table";

        ok my $info = $engine->get_info($table_info), 'get info for table';
        foreach my $rec (@fields_info) {
            my ($name, $type) = @{$rec};
            $type =~ s{\(.*\)}{}gmx;       # just the type
            $type =~ s{\s+precision}{}gmx; # just 'double'
            $type =~ s{bigint}{int64}gmx;  # made with 'bigint' but is 'int64'
            is $info->{$name}{type}, $type, "type for field '$name' is '$type'";
        }


        ######################################################################
        # Test the DB writer and prepare test tables

        # Change target_params hash ref key from 'uri' to 'output_uri',
        # as required by App::Transfer::Options
        my $target_params = [ 'output_uri', $p{target_params}[1] ];
        my $options_href = {
            @{ $target_params || [] },
        };
        ok my $recipe_w = $transfer->recipe, 'get the recipe object again';
        ok my $options_w = App::Transfer::Options->new(
            transfer => $transfer,
            options  => $options_href,
            rw_type  => 'writer',
        ), 'options object';
        ok my $writer = App::Transfer::Writer->load({
            transfer => $transfer,
            recipe   => $recipe_w,
            writer   => 'db',
            options  => $options_w,
        }), 'new db writer object';

        my @fields_look = (
            [ 'siruta', 'integer' ],
            [ 'localitate', 'varchar(100)' ],
        );
        my $fields_look = join " \n , ", map { join ' ', @{$_} } @fields_look;
        my $table_dict = 'test_dict';

        # Create the dictionary test table

        $ddl = qq{CREATE TABLE $table_dict ( \n   $fields_look \n);};

        ok $engine->dbh->do($ddl), "create '$table_dict' table";

        my $records_dict = [
            {   siruta     => 86357,
                localitate => 'Izvoru Mureșului',
            },
            {   siruta     => 63394,
                localitate => 'Sfîntu Gheorghe',
            },
            {   siruta     => 41104,
                localitate => 'Podu Oltului',
            },
            {   siruta     => 83428,
                localitate => 'Băile Tușnad',
            },
            {   siruta     => 40198,
                localitate => 'Brașov',
            },
        ];

        # Insert the records
        foreach my $row ( @{$records_dict} ) {
            $writer->insert($table_dict, $row);
        }
        is $writer->records_inserted, 5, 'records inserted: 5';
        is $writer->records_skipped, 0, 'records skipped: 0';

        ### The source table

        ok $writer = App::Transfer::Writer->load({
            transfer => $transfer,
            recipe   => $recipe_w,
            writer   => 'db',
            options  => $options_w,
        }), 'a new db writer object';

        my @fields_db = (
            [ 'id', 'integer' ],
            [ 'denumire', 'varchar(100)' ],
        );
        my $fields_db = join " \n , ", map { join ' ', @{$_} } @fields_db;
        my $table_db  = 'test_db';

        # Create the test table
        $ddl = qq{CREATE TABLE $table_db ( \n   $fields_db \n);};

        ok $engine->dbh->do($ddl), "create '$table_db' table";

        my $records_db = [
            {   id         => 1,
                denumire => 'Izvorul Mures',
            },
            {   id         => 2,
                denumire => 'Sfantu Gheorghe',
            },
            {   id         => 3,
                denumire => 'Podu Olt',
            },
            {   id         => 4,
                denumire => 'Baile Tusnad',
            },
            {   id         => 5,
                denumire => 'Brașov',
            },
        ];

        # Insert some the records
        foreach my $row ( @{$records_db} ) {
            $writer->insert($table_db, $row);
        }
        is $writer->records_inserted, 5, 'records inserted: 5';
        is $writer->records_skipped, 0, 'records skipped: 0';

        ### The destination table

        my @fields_import = (
            [ 'id', 'integer' ],
            [ 'cod', 'integer' ],
            [ 'denloc', 'varchar(100)' ],
        );
        my $fields_import = join " \n , ",
            map { join ' ', @{$_} } @fields_import;
        my $table_import = 'test_import';

        # Create the test table
        $ddl = qq{CREATE TABLE $table_import ( \n   $fields_import \n);};

        ok $engine->dbh->do($ddl), "create '$table_import' table";


        ######################################################################
        # Test the DB reader

        # Change target_params hash ref key from 'uri' to 'input_uri',
        # as required by App::Transfer::Options
        $target_params = [ 'input_uri', $p{target_params}[1] ];
        $options_href = {
            @{ $target_params || [] },
        };
        ok my $recipe_r = $transfer->recipe, 'get the recipe object again';
        ok my $options_r = App::Transfer::Options->new(
            transfer => $transfer,
            options  => $options_href,
            rw_type  => 'reader',
        ), 'options object';
        ok my $reader = App::Transfer::Reader->load({
            transfer => $transfer,
            recipe   => $recipe_r,
            reader   => 'db',
            options  => $options_r,
        }), 'new db reader object';

        # Test for failure
        throws_ok { $reader->get_fields('nonexistenttable') }
        'App::Transfer::X',
            'Should have error for nonexistent table';
        is $@->ident, 'reader',
            'Nonexistent table error ident should be "reader"';
        is $@->message, __( 'Table "nonexistenttable" does not exists' ),
            'Nonexistent table error should be correct';

        ok my $table_r = $reader->table, 'get the table name';
        is $table_r, $table_db, 'check the table name';

        ### XXX Needs another recipe
        # throws_ok { $reader->get_fields($table) }
        #     qr/\QColumns from the map file not found in the/,
        #     'Should get an exception for nonexistent columns';

        ok my $fields = $reader->get_fields($table_db), 'table fields';
        is scalar @{$fields}, 2, 'got 2 fields';

        ok my $records = $reader->get_data, 'get data for table';
        ok scalar @{$records} > 0, 'got some records';


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookup_db trafo method
        # With field_dst as array ref

        # The step config section
        # <step>
        #   type                = lookup_db
        #   datasource          = test_dict
        #   hints               = localitati
        #   <field_src>
        #     denumire          = localitate
        #   </field_src>
        #   method              = lookup_in_dbtable
        #   <field_dst>
        #     denumire          = localitate
        #   </field_dst>
        #   <field_dst>
        #     cod               = siruta
        #   </field_dst>
        # </step>
        subtest 'a. type_lookup_db with dst: 2 mappings (AoH)' => sub {

        my $conf_lookup_db = {
            row => {
                step => {
                    type       => 'lookup_db',
                    field_src  => { denumire => 'localitate' },
                    field_dst  =>
                        [ { denloc => 'localitate' }, { cod => 'siruta' }, ],
                    hints      => 'localitati',
                    method     => 'lookup_in_dbtable',
                    datasource => 'test_dict',
                },
            },
        };

        ok my $transform = App::Transfer::Transform->new,
            'a. new transform object';

        ok my $tr = App::Transfer::Recipe::Transform->new($conf_lookup_db),
            'a. lookup_db test step';
        isa_ok $tr, 'App::Transfer::Recipe::Transform', 'a. recipe transform';

        ok my $step = $tr->row->[0], 'a. the step';

        ok $info = $engine->get_info($table_import),
            'a. get info for table';

        ok my $command = App::Transfer::RowTrafos->new(
            recipe    => $transfer->recipe,
            transform => $transform,
            engine    => $engine,
            info      => $info,
        ), 'a. new command';

        # Input records
        my $records_4a = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
        ];

        my @records;
        foreach my $rec ( @{$records_4a} ) {
            push @records, $command->type_lookup_db( $step, $rec );
        }

        my $expected = [
            {   id       => 1,
                denumire => 'Izvorul Mures',
                cod      => 86357,
                denloc   => 'Izvoru Mureșului',
            },
            {   id       => 2,
                denumire => 'Sfantu Gheorghe',
                cod      => 63394,
                denloc   => 'Sfîntu Gheorghe',
            },
            {   id       => 3,
                denumire => 'Podu Olt',
                cod      => 41104,
                denloc   => 'Podu Oltului',
            },
            {   id       => 4,
                denumire => 'Baile Tusnad',
                cod      => 83428,
                denloc   => 'Băile Tușnad',
            },
            {   id       => 5,
                denumire => 'Brașov',
                cod      => 40198,
                denloc   => 'Brașov',
            },
        ];

        is_deeply \@records, $expected, 'a. resulting records';

        };                      # subtest a.


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookup_db trafo method
        # With field_dst as hash ref

        # The step config section
        # <step>
        #   type                = lookup_db
        #   datasource          = test_dict
        #   hints               = localitati
        #   <field_src>
        #     denumire          = localitate
        #   </field_src>
        #   method              = lookup_in_dbtable
        #   <field_dst>
        #     denloc            = localitate
        #     cod               = siruta
        #   </field_dst>
        # </step>
        subtest 'b. type_lookup_db with dst: 2 mappings' => sub {

        my $conf_lookup_db = {
            row => {
                step => {
                    type       => 'lookup_db',
                    field_src  => { denumire => 'localitate' },
                    field_dst  => { denloc => 'localitate', cod => 'siruta' },
                    hints      => 'localitati',
                    method     => 'lookup_in_dbtable',
                    datasource => 'test_dict',
                },
            },
        };

        ok my $transform = App::Transfer::Transform->new,
            'b. new transform object';

        ok my $tr = App::Transfer::Recipe::Transform->new($conf_lookup_db),
            'b. lookup_db test step';
        isa_ok $tr, 'App::Transfer::Recipe::Transform', 'b. recipe transform';

        ok my $step = $tr->row->[0], 'b. the step again';

        ok $info = $engine->get_info($table_import),
            'b. get info for table';

        ok my $command = App::Transfer::RowTrafos->new(
            recipe    => $transfer->recipe,
            transform => $transform,
            engine    => $engine,
            info      => $info,
        ), 'b. new command';

        # Input records
        my $records_4b = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
        ];

        my @records;
        foreach my $rec ( @{$records_4b} ) {
            push @records, $command->type_lookup_db( $step, $rec );
        }

        my $expected = [
            {   id       => 1,
                denumire => 'Izvorul Mures',
                cod      => 86357,
                denloc   => 'Izvoru Mureșului',
            },
            {   id       => 2,
                denumire => 'Sfantu Gheorghe',
                cod      => 63394,
                denloc   => 'Sfîntu Gheorghe',
            },
            {   id       => 3,
                denumire => 'Podu Olt',
                cod      => 41104,
                denloc   => 'Podu Oltului',
            },
            {   id       => 4,
                denumire => 'Baile Tusnad',
                cod      => 83428,
                denloc   => 'Băile Tușnad',
            },
            {   id       => 5,
                denumire => 'Brașov',
                cod      => 40198,
                denloc   => 'Brașov',
            },
        ];

        is_deeply \@records, $expected, 'b. resulting records again';

        };                      # subtest b.


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookup_db trafo method
        # With field_dst as hash ref

        # The step config section
        # <step>
        #   type                = lookup_db
        #   datasource          = test_dict
        #   hints               = localitati
        #   <field_src>
        #     denumire          = localitate
        #   </field_src>
        #   method              = lookup_in_dbtable
        #   <field_dst>
        #     denloc            = localitate
        #   </field_dst>
        #   field_dst           = siruta
        # </step>
        subtest 'c. type_lookup_db with dst: a mapping and a field' => sub {

        my $conf_lookup_db = {
            row => {
                step => {
                    type       => 'lookup_db',
                    field_src => { denumire => 'localitate' },
                    field_dst => [ { denloc => 'localitate' }, 'siruta' ],
                    hints      => 'localitati',
                    method     => 'lookup_in_dbtable',
                    datasource => 'test_dict',
                },
            },
        };

        ok my $transform = App::Transfer::Transform->new,
            'c. new transform object';

        ok my $tr = App::Transfer::Recipe::Transform->new($conf_lookup_db),
            'c. lookup_db test step';
        isa_ok $tr, 'App::Transfer::Recipe::Transform', 'c. recipe transform';

        ok my $step = $tr->row->[0], 'c. the step again';

        ok my $info = $engine->get_info($table_import),
            'c. get info for table';

        # Manipulate info
        $info->{siruta} = {
            defa        => undef,
            is_nullable => undef,
            length      => 4,
            name        => "cod",
            pos         => 1,
            prec        => 0,
            scale       => 0,
            type        => "integer",
        },

        ok my $command = App::Transfer::RowTrafos->new(
            recipe    => $transfer->recipe,
            transform => $transform,
            engine    => $engine,
            info      => $info,
        ), 'c. new command';

        # Input records
        my $records_4c = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
        ];

        my @records;
        foreach my $rec ( @{$records_4c} ) {
            push @records, $command->type_lookup_db( $step, $rec );
        }

        my $expected = [
            {   id       => 1,
                denumire => 'Izvorul Mures',
                siruta   => 86357,
                denloc   => 'Izvoru Mureșului',
            },
            {   id       => 2,
                denumire => 'Sfantu Gheorghe',
                siruta   => 63394,
                denloc   => 'Sfîntu Gheorghe',
            },
            {   id       => 3,
                denumire => 'Podu Olt',
                siruta   => 41104,
                denloc   => 'Podu Oltului',
            },
            {   id       => 4,
                denumire => 'Baile Tusnad',
                siruta   => 83428,
                denloc   => 'Băile Tușnad',
            },
            {   id       => 5,
                denumire => 'Brașov',
                siruta   => 40198,
                denloc   => 'Brașov',
            },
        ];

        is_deeply \@records, $expected, 'c. resulting records again';

        };                      # subtest c.


        ######################################################################
        # Test the lookup_in_ds plugin and type_lookup trafo method

        # The step config section

        subtest 'd. type_lookup' => sub {

        my $conf_lookup = {
            transform => {
                row => {
                    step => {
                        type       => 'lookup',
                        field_src  => 'categorie',
                        field_dst  => 'categ_id',
                        method     => 'lookup_in_ds',
                        datasource => 'categories',
                    }
                }
            },
        };

        ok my $transform = App::Transfer::Transform->new,
            'd. new transform object';

        ok my $tr = App::Transfer::Recipe::Transform->new(
            $conf_lookup->{transform} ), 'd. lookup test step';
        isa_ok $tr, 'App::Transfer::Recipe::Transform', 'd. recipe transform';

        ok my $step = $tr->row->[0], 'd. the step';

        ok $info = $engine->get_info($table_import),
            'd. get info for table';

        ok my $command = App::Transfer::RowTrafos->new(
            recipe    => $transfer->recipe,
            transform => $transform,
            engine    => $engine,
            info      => $info,
        ), 'd. new row trafo command';

        my @records;
        foreach my $rec ( @{$records} ) {
            push @records, $command->type_lookup_db( $step, $rec );
        }

        # my $expected = [
        # ];

        say "*** rezult:";
        dd @records;

        # # is_deeply \@records, $expected, 'resulting records';

        };                      # subtest


        ######################################################################
        # All done.
        done_testing;
    };
}

1;
