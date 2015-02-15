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
use App::Transfer::Transform;

use Data::Dump;

BEGIN { Log::Log4perl->init('t/log.conf') }

# Just die on warnings.
use Carp; BEGIN { $SIG{__WARN__} = \&Carp::confess }

sub run {
    my ( $self, %p ) = @_;

    my $class           = $p{class};
    my @trafo_params = @{ $p{trafo_params} || [] };
    my $mock_transfer   = Test::MockModule->new('App::Transfer');

    can_ok $class, qw(
        get_info
        table_exists
    );

    subtest 'live database' => sub {

        my $transfer = App::Transfer->new;

        ok my $target = App::Transfer::Target->new(
            transfer => $transfer,
            @{ $p{target_params} || [] },
        ), 'new target';
        isa_ok $target, 'App::Transfer::Target', 'target';

        ok my $engine = $class->new(
            transfer => $transfer,
            target   => $target,
            @{ $p{engine_params} || [] },
        ), 'new engine';
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

        throws_ok { $engine->dbh->do('INSERT blah INTO __bar_____') }
            'App::Transfer::X',
            'Database error should be converted to Transfer exception';
        is $@->ident, $class->key, 'Ident should be the engine';
        ok $@->message, 'The message should be from the translation';

        my $input_options  = { input_uri  => $p{target_params}[1] };
        my $output_options = { output_uri => $p{target_params}[1] };

        ok my $trafo = App::Transfer::Transform->new(
            transfer       => $transfer,
            engine         => $engine,
            input_options  => $input_options,
            output_options => $output_options,
            @trafo_params,
        ), 'new trafo instance';

        ok my $trafos_row = $trafo->recipe->transform->row, 'row trafos';


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
            {   siruta     => 92792,
                localitate => 'Albesti',
            },
            {   siruta     => 60954,
                localitate => 'Albesti',
            },
        ];

        # Insert the records

        foreach my $row ( @{$records_dict} ) {
            $trafo->writer->insert($table_dict, $row);
        }
        is $trafo->writer->records_inserted, 7, 'records inserted: 7';
        is $trafo->writer->records_skipped, 0, 'records skipped: 0';

        # The source table

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

        $trafo->writer->reset_inserted;

        # Insert the records

        foreach my $row ( @{$records_db} ) {
            $trafo->writer->insert($table_db, $row);
        }
        is $trafo->writer->records_inserted, 5, 'records inserted: 5';
        is $trafo->writer->records_skipped, 0, 'records skipped: 0';

        # The destination table

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

        # Test for failure
        throws_ok { $trafo->reader->get_fields('nonexistenttable') }
        'App::Transfer::X',
            'Should have error for nonexistent table';
        is $@->ident, 'reader',
            'Nonexistent table error ident should be "reader"';
        is $@->message, __( 'Table "nonexistenttable" does not exists' ),
            'Nonexistent table error should be correct';

        ok my $table_r = $trafo->reader->table, 'get the table name';
        is $table_r, $table_db, 'check the table name';

        ### XXX Needs another recipe
        # throws_ok { $trafo->reader->get_fields($table) }
        #     qr/\QColumns from the map file not found in the/,
        #     'Should get an exception for nonexistent columns';

        ok my $fields = $trafo->reader->get_fields($table_db), 'table fields';
        is scalar @{$fields}, 2, 'got 2 fields';

        ok my $records = $trafo->reader->get_data, 'get data for table';
        ok scalar @{$records} > 0, 'got some records';

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

        ###

        # ######################################################################
        # # Test the lookup_in_dbtable plugin and type_lookup_db trafo method
        # # With field_dst as array ref

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
        #   <field_dst>
        #     cod               = siruta
        #   </field_dst>
        # </step>
        subtest 'a. type_lookup_db with dst: 2 mappings (AoH)' => sub {

        my $records_4a = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
        ];

        ok my $step = shift @{$trafos_row}, 'the first step';

        ok my $p = $trafo->build_lookup_db_para($step), 'build para';

        my @records;
        foreach my $rec ( @{$records_4a} ) {
            my $id = $rec->{id} // '?';
            $p->{logstr} = "[id:$id]";
            push @records, $trafo->type_lookup_db( $p, $rec );
        }

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

        my $records_4b = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
        ];

        ok my $step = shift @{$trafos_row}, 'the first step';

        ok my $p = $trafo->build_lookup_db_para($step), 'build para';

        my @records;
        foreach my $rec ( @{$records_4b} ) {
            my $id = $rec->{id} // '?';
            $p->{logstr} = "[id:$id]";
            push @records, $trafo->type_lookup_db( $p, $rec );
        }

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

        my $records_4c = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brașov",          id => 5 },
            { denumire => "Albesti",         id => 6 },
        ];   # XXX Fails for "Albești" with Wide character in print...

        ok my $step = shift @{$trafos_row}, 'the first step';

        ok my $p = $trafo->build_lookup_db_para($step), 'build para';

        my @records;
        foreach my $rec ( @{$records_4c} ) {
            my $id = $rec->{id} // '?';
            $p->{logstr} = "[id:$id]";
            push @records, $trafo->type_lookup_db( $p, $rec );
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
            {   id       => 6,
                denumire => 'Albesti',
                siruta   => undef,
                denloc   => undef,
            },
        ];

        is_deeply \@records, $expected, 'c. resulting records again';

        };                      # subtest c.


        ######################################################################
        # Test the lookup_in_ds plugin and type_lookup trafo method

        # The step config section

        # subtest 'd. type_lookup' => sub {

        # my $conf_lookup = {
        #     transform => {
        #         row => {
        #             step => {
        #                 type       => 'lookup',
        #                 field_src  => 'categorie',
        #                 field_dst  => 'categ_id',
        #                 method     => 'lookup_in_ds',
        #                 datasource => 'categories',
        #             }
        #         }
        #     },
        # };

        # my @records;
        # foreach my $rec ( @{$records} ) {
        #     push @records, $trafo->type_lookup_db( $step, $rec );
        # }

        # # my $expected = [
        # # ];

        # say "*** rezult:";
        # dd @records;

        # # # is_deeply \@records, $expected, 'resulting records';

        # };                      # subtest


        ######################################################################
        # All done.
        done_testing;
    };
}

1;
