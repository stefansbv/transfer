package DBIEngineTest;
#
# Adapted from Sqitch by theory.
#
# Changed to to use only ASCII because of:
# Wide character in print at lib/site_perl/5.14.4/Test/Builder.pm line 1826.
# when is_deeply reports failure
#
use 5.010;
use strict;
use warnings;
use utf8;
use Locale::TextDomain 1.20 qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

use Try::Tiny;
use Test::Most;
use Test::MockModule;
use Log::Log4perl;
use Capture::Tiny 0.12 qw(capture_stdout capture_merged);

use App::Transfer::Config;
use App::Transfer::Transform;

BEGIN { Log::Log4perl->init('t/log.conf') }

binmode STDOUT, ':utf8';

# Just die on warnings.
use Carp; BEGIN { $SIG{__WARN__} = \&Carp::confess }

sub run {
    my ( $self, %p ) = @_;

    my $class        = $p{class};
    my @trafo_params = @{ $p{trafo_params} || [] };

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
            input_options  => $input_options,
            output_options => $output_options,
            @trafo_params,
        ), 'new trafo instance';

        ok my $trafos_row = $trafo->recipe->transform->row, 'row trafos';


        #######################################################################
        # Test the info methods

        # Avoid:
        # Negative repeat count does nothing at
        # .../perls/5.24.0t/lib/site_perl/5.24.0/Perl6/Form.pm line 1209
        {
            require Test::NoWarnings;
            my $trans1 = __('Recipe:');
            like capture_stdout { $trafo->job_intro },
                 qr/$trans1/ms,
                'job intro should work';

            my $trans2 = __('Input:');
            like capture_stdout { $trafo->job_info_input_db },
                qr/$trans2/ms,
                'job info input db should work';

            my $trans3 = __('Output:');
            like capture_stdout { $trafo->job_info_output_db },
                qr/$trans3/ms,
            'job info input db should work';

            throws_ok { $trafo->transfer_file2db }
                'App::Transfer::X',
                'Should have error for nonexistent table';

            throws_ok { $trafo->transfer_db2db }
                'App::Transfer::X',
                'Should have error for nonexistent table';

            throws_ok { $trafo->transfer_db2file }
                'App::Transfer::X',
                'Should have error for nonexistent table';
        }

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
        # Test someting specific for Pg

        if ($class eq 'App::Tpda3Dev::Engine::pg') {
            my ($sch, $tbl) = $engine->get_schema_name('schema_name.table_name');
            is $sch, 'schema_name', 'schema';
            is $tbl, 'table_name', 'table';

            ($sch, $tbl) = $engine->get_schema_name('table_name');
            is $sch, undef, 'schema';
            is $tbl, 'table_name', 'table';
        }


        ######################################################################
        # Test the engine methods

        my @fields_info = (
            [ 'field_00', 'integer' ],
            [ 'field_01', 'char(1)' ],
            [ 'field_02', 'date' ],
            [ 'field_03', 'integer' ],
            [ 'field_04', 'numeric(9,3)' ],
            [ 'field_05', 'smallint' ],
            [ 'field_06', 'varchar(10)' ],
        );

        my @flds = map { $_->[0] } @fields_info;
        my $field_def = join " \n , ", map { join ' ', @{$_} } @fields_info;
        my $table_frn = 'test_info_frn';
        my $table     = 'test_info';

        my $ddl0 = qq{CREATE TABLE $table_frn (
                          field_10 CHAR(1)
                        , field_11 VARCHAR(10)
                        , CONSTRAINT pk_${table_frn}_field_10
                             PRIMARY KEY (field_10)
                     )
        };

        ok $engine->dbh->do($ddl0), "create '$table_frn' table";

        my $ddl = qq{CREATE TABLE $table ( \n   $field_def \n
                         , CONSTRAINT pk_${table}_field_00
                             PRIMARY KEY (field_00)
                         , CONSTRAINT fk__${table}_field_01
                             FOREIGN KEY (field_01)
                               REFERENCES $table_frn (field_10)
                                          ON DELETE NO ACTION
                                          ON UPDATE NO ACTION
                     )
        };

        ok $engine->dbh->do($ddl), "create '$table' table";

        ok $engine->table_exists($table), "$table table exists";

        cmp_deeply $engine->table_keys($table_frn), ['field_10'],
            'the pk keys data should match';

        cmp_deeply $engine->table_keys($table), ['field_00'],
            'the pk keys data should match';

        cmp_deeply $engine->table_keys( $table, 'foreign' ),
            ['field_01'],
            'the fk keys data should match';

        my $cols = $engine->get_columns($table);
        cmp_deeply $cols, \@flds, 'table columns';

        cmp_deeply $engine->table_list(), [$table_frn, $table], 'table list';

        ok my $info = $engine->get_info($table), 'get info for table';
        foreach my $rec (@fields_info) {
            my ($name, $type) = @{$rec};
            $type =~ s{\(.*\)}{}gmx;       # just the type
            $type =~ s{\s+precision}{}gmx; # just 'double', delete 'precision'
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
                localitate => 'Izvoru Muresului',
            },
            {   siruta     => 63394,
                localitate => 'Sfintu Gheorghe',
            },
            {   siruta     => 41104,
                localitate => 'Podu Oltului',
            },
            {   siruta     => 83428,
                localitate => 'Baile Tusnad',
            },
            {   siruta     => 40198,
                localitate => 'Brasov',
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
                denumire => 'Brasov',
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

        throws_ok { $trafo->validate_destination }
            'App::Transfer::X',
            'Should have error for destination fields not found';


        ######################################################################
        # Test the DB reader

        # Test for failure
        throws_ok { $trafo->reader->get_fields('nonexistenttable') }
        'App::Transfer::X',
            'Should have error for nonexistent table';
        is $@->ident, 'reader',
            'Nonexistent table error ident should be "reader"';
        is $@->message, __x( "The '{table}' table does not exists or is not readable", table => 'nonexistenttable' ),
            'Nonexistent table error should be correct';

        ok my $table_r = $trafo->reader->table, 'get the table name';
        is $table_r, $table_db, 'check the table name';

        ### XXX Needs another recipe
        # throws_ok { $trafo->reader->get_fields($table) }
        #     qr/\QColumns from the map file not found in the/,
        #     'Should get an exception for nonexistent columns';

        ok my $fields = $trafo->reader->get_fields($table_db), 'table fields';
        is scalar @{$fields}, 2, 'get 2 fields';

        ok my $iter = $trafo->reader->contents_iter, 'get the iterator';
        isa_ok $iter, 'MooseX::Iterator::Array', 'iterator';

        my $count = 0;
        while ( $iter->has_next ) {
            my $rec = $iter->next;
            cmp_deeply $rec, $records_db->[$count], "record  data";
            $count++;
        }

        is $trafo->reader->record_count, $count, 'counted records match record_count';

        ###
        
        my $expected = [
            {   id       => 1,
                denumire => 'Izvorul Mures',
                cod      => 86357,
                denloc   => 'Izvoru Muresului',
            },
            {   id       => 2,
                denumire => 'Sfantu Gheorghe',
                cod      => 63394,
                denloc   => 'Sfintu Gheorghe',
            },
            {   id       => 3,
                denumire => 'Podu Olt',
                cod      => 41104,
                denloc   => 'Podu Oltului',
            },
            {   id       => 4,
                denumire => 'Baile Tusnad',
                cod      => 83428,
                denloc   => 'Baile Tusnad',
            },
            {   id       => 5,
                denumire => 'Brasov',
                cod      => 40198,
                denloc   => 'Brasov',
            },
        ];

        ###

        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookupdb trafo method
        # With field_dst as array ref

        # The step config section
        # <step>
        #   type                = lookupdb
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
        subtest 'a. type_lookupdb with dst: 2 mappings (AoH)' => sub {

        ok my $step = shift @{$trafos_row}, 'the a. step';

        my $records_4a = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brasov",          id => 5 },
        ];

        my @records;
        foreach my $rec ( @{$records_4a} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookupdb( $step, $rec, $logstr );
        }

        is_deeply \@records, $expected, 'a. resulting records';

        };                      # subtest a.


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookupdb trafo method
        # With field_dst as hash ref

        # The step config section
        # <step>
        #   type                = lookupdb
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
        subtest 'b. type_lookupdb with dst: 2 mappings' => sub {

        my $records_4b = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brasov",          id => 5 },
        ];

        ok my $step = shift @{$trafos_row}, 'the b. step';

        my @records;
        foreach my $rec ( @{$records_4b} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookupdb( $step, $rec, $logstr );
        }

        is_deeply \@records, $expected, 'b. resulting records again';

        };                      # subtest b.


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookupdb trafo method
        # With field_dst as hash ref

        # The step config section
        # <step>
        #   type                = lookupdb
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
        subtest 'c. type_lookupdb with dst: a mapping and a field' => sub {

        my $records_4c = [
            { denumire => "Izvorul Mures",   id => 1 },
            { denumire => "Sfantu Gheorghe", id => 2 },
            { denumire => "Podu Olt",        id => 3 },
            { denumire => "Baile Tusnad",    id => 4 },
            { denumire => "Brasov",          id => 5 },
            { denumire => "Albesti",         id => 6 },
        ];

        ok my $step = shift @{$trafos_row}, 'the c. step';

        my @records;
        foreach my $rec ( @{$records_4c} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookupdb( $step, $rec, $logstr );
        }

        my $expected_4c = [
            {   id       => 1,
                denumire => 'Izvorul Mures',
                siruta   => 86357,
                denloc   => 'Izvoru Muresului',
            },
            {   id       => 2,
                denumire => 'Sfantu Gheorghe',
                siruta   => 63394,
                denloc   => 'Sfintu Gheorghe',
            },
            {   id       => 3,
                denumire => 'Podu Olt',
                siruta   => 41104,
                denloc   => 'Podu Oltului',
            },
            {   id       => 4,
                denumire => 'Baile Tusnad',
                siruta   => 83428,
                denloc   => 'Baile Tusnad',
            },
            {   id       => 5,
                denumire => 'Brasov',
                siruta   => 40198,
                denloc   => 'Brasov',
            },
            {   id       => 6,
                denumire => 'Albesti',
                siruta   => undef,
                denloc   => undef,
            },
        ];

        is_deeply \@records, $expected_4c, 'c. resulting records again';

        };                      # subtest c.


        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookupdb trafo method
        # With field_dst as hash ref

        # The step config section
        # <step>
        #   type                = lookupdb
        #   datasource          = test_dict
        #   field_src           = localitate
        #   method              = lookup_in_dbtable
        #   field_dst           = siruta
        # </step>
        subtest 'd. type_lookupdb with dst: a mapping and a field' => sub {

        my $records_4d = [
            { localitate => "Izvoru Muresului", id => 1 },
            { localitate => "Sfintu Gheorghe",  id => 2 },
            { localitate => "Podu Oltului",     id => 3 },
            { localitate => "Baile Tusnad",     id => 4 },
            { localitate => "Brasov",           id => 5 },
            { localitate => "Albesti",          id => 6 },
        ];

        ok my $step = shift @{$trafos_row}, 'the d. step';

        my @records;
        foreach my $rec ( @{$records_4d} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookupdb( $step, $rec, $logstr );
        }

        my $expected_4d = [
            {   id       => 1,
                localitate => 'Izvoru Muresului',
                siruta   => 86357,
            },
            {   id       => 2,
                localitate => 'Sfintu Gheorghe',
                siruta   => 63394,
            },
            {   id       => 3,
                localitate => 'Podu Oltului',
                siruta   => 41104,
            },
            {   id       => 4,
                localitate => 'Baile Tusnad',
                siruta   => 83428,
            },
            {   id       => 5,
                localitate => 'Brasov',
                siruta   => 40198,
            },
            {   id       => 6,
                localitate => 'Albesti',
                siruta   => undef,
            },
        ];

        is_deeply \@records, $expected_4d, 'd. resulting records again';

        };                      # subtest d.

        ######################################################################
        # Test the lookup_in_dbtable plugin and type_lookupdb trafo method
        # With field_dst as hash ref and the IGNORECASE attribute on

        # The step config section
        # <step>
        #   type                = lookupdb
        #   datasource          = test_dict
        #   field_src           = localitate
        #   method              = lookup_in_dbtable
        #   field_dst           = siruta
        # </step>
        subtest 'd2. type_lookupdb with dst: a mapping and a field' => sub {

        my $records_4d2 = [
            { localitate => "IZVORU MUREŞULUI", id => 1 },
            { localitate => "Sfîntu GHEORGHE",  id => 2 },
            { localitate => "PODU Oltului",     id => 3 },
            { localitate => "Băile Tuşnad",     id => 4 },
            { localitate => "BRAȘOV",           id => 5 },
            { localitate => "Albești",          id => 6 },
        ];

        ok my $step = shift @{$trafos_row}, 'the d.2 step';

        my @records;
        foreach my $rec ( @{$records_4d2} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookupdb( $step, $rec, $logstr );
        }

        my $expected_4d2 = [
            {   id       => 1,
                localitate => 'IZVORU MUREŞULUI',
                siruta   => 86357,
            },
            {   id       => 2,
                localitate => 'Sfîntu GHEORGHE',
                siruta   => 63394,
            },
            {   id       => 3,
                localitate => 'PODU Oltului',
                siruta   => 41104,
            },
            {   id       => 4,
                localitate => 'Băile Tuşnad',
                siruta   => 83428,
            },
            {   id       => 5,
                localitate => 'BRAȘOV',
                siruta   => 40198,
            },
            {   id       => 6,
                localitate => 'Albești',
                siruta   => undef,
            },
        ];

        is_deeply \@records, $expected_4d2, 'd.2 resulting records again';

        };                      # subtest 2.d


        ######################################################################
        # Test the split_field plugin and type_split trafo method

        # The step config section
        # <step>
        #   type                = split
        #   separator           = ,
        #   field_src           = adresa
        #   method              = split_field
        #   field_dst           = localitate
        #   field_dst           = strada
        #   field_dst           = numarul
        # </step>
        subtest 'e. split' => sub {

        ok my $step = shift @{$trafos_row}, 'the e. step';

        my $records_4e = [
            { adresa => "Izvorul Mures, str. Brasovului, nr. 5", id => 1 },
            { adresa => "Sfintu Gheorghe,  str. Covasna",        id => 2 },
            { adresa => "Brasov, str. Bucurestilor,    nr. 23",  id => 3 },
        ];

        my @records;
        foreach my $rec ( @{$records_4e} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_split( $step, $rec, $logstr );
        }

        my $expected_4e = [
            {   adresa     => "Izvorul Mures, str. Brasovului, nr. 5",
                id         => 1,
                localitate => "Izvorul Mures",
                numarul    => "nr. 5",
                strada     => "str. Brasovului",
            },
            {   adresa     => "Sfintu Gheorghe,  str. Covasna",
                id         => 2,
                localitate => "Sfintu Gheorghe",
                strada     => "str. Covasna",
            },
            {   adresa     => "Brasov, str. Bucurestilor,    nr. 23",
                id         => 3,
                localitate => "Brasov",
                numarul    => "nr. 23",
                strada     => "str. Bucurestilor",
            },
        ];

        is_deeply \@records, $expected_4e, 'e. resulting records';

        };                      # subtest e.


        ######################################################################
        # Test the join_field plugin and type_join trafo method

        # The step config section
        # <step>
        #   type                = join
        #   separator           = ', '
        #   field_src           = localitate
        #   field_src           = strada
        #   field_src           = numarul
        #   method              = join_field
        #   field_dst           = adresa
        # </step>
        subtest 'f. join' => sub {

        ok my $step = shift @{$trafos_row}, 'the f. step';

        my $records_4f = [
            {   id         => 1,
                localitate => "Izvorul Mures",
                numarul    => "nr. 5",
                strada     => "str. Brasovului",
            },
            {   id         => 2,
                localitate => "Sfintu Gheorghe",
                strada     => "str. Covasna",
            },
            {   id         => 3,
                localitate => "Brasov",
                numarul    => "nr. 23",
                strada     => "str. Bucurestilor",
            },
        ];

        my @records;
        foreach my $rec ( @{$records_4f} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_join( $step, $rec, $logstr );
        }

        my $expected_4f = [
            {   adresa     => "Izvorul Mures, str. Brasovului, nr. 5",
                id         => 1,
                localitate => "Izvorul Mures",
                numarul    => "nr. 5",
                strada     => "str. Brasovului",
            },
            {   adresa     => "Sfintu Gheorghe, str. Covasna",
                id         => 2,
                localitate => "Sfintu Gheorghe",
                strada     => "str. Covasna",
            },
            {   adresa     => "Brasov, str. Bucurestilor, nr. 23",
                id         => 3,
                localitate => "Brasov",
                numarul    => "nr. 23",
                strada     => "str. Bucurestilor",
            },
        ];

        is_deeply \@records, $expected_4f, 'f. resulting records';

        };                      # subtest f.


        ######################################################################
        # Test the move_filtered plugin and type_copy trafo method
        # with datasource

        # The step config section
        # <step>
        #   type                = copy
        #   datasource          = status
        #   field_src           = status
        #   method              = move_filtered
        #   field_dst           = observations
        #   attributes          = MOVE | APPENDSRC
        # </step>
        subtest 'g. copy' => sub {

        ok my $step = shift @{$trafos_row}, 'the g. step';

        my $records_4g = [
            { status => "Cancelled",      id => 1 },
            { status => "Disputed",       id => 2 },
            { status => "call the owner", id => 3 },
            { status => "On Hold",        id => 4 },
            { status => "tel 1234567890", id => 5, observations => 'some obs' },
            { status => "Shipped",        id => 6 },
        ];

        my @records;
        foreach my $rec ( @{$records_4g} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_copy( $step, $rec, $logstr );
        }

        my $expected_4g = [
            { id => 1, status => "Cancelled" },
            { id => 2, status => "Disputed" },
            { id => 3, observations => "status: call the owner", status => undef
            },
            { id => 4, status => "On Hold" },
            { id => 5, observations => "some obs, status: tel 1234567890", status => undef
            },
            { id => 6, status => "Shipped" },
        ];

        is_deeply \@records, $expected_4g, 'g. resulting records';

        };                      # subtest g.


        ######################################################################
        # Test the copy_nonzero plugin and type_batch trafo method

        # The step config section
        # h.
        # <step>
        #   type              = batch
        #   field_src         = debit
        #   field_src         = credit
        #   method            = copy_nonzero
        #   field_dst         = suma
        #   attributes        = MOVE | REPLACENULL
        # </step>
        subtest 'h. batch' => sub {

        ok my $step = shift @{$trafos_row}, 'the h. step';

        my $records_4h = [
            { debit => 100, credit => 0   },
            { debit => 0,   credit => 100 },
        ];

        my @records;
        foreach my $rec ( @{$records_4h} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_batch( $step, $rec, $logstr );
        }

        my $expected_4h = [
            { debit => undef, credit => undef, suma =>  100 },
            { debit => undef, credit => undef, suma => -100 },
        ];

        is_deeply \@records, $expected_4h, 'g. resulting records';

        };                      # subtest h.


        ######################################################################
        # Test the lookup_in_ds plugin and type_lookup_ds trafo method

        # The step config section
        # # i.
        # <step>
        #   type                = lookup
        #   datasource          = category
        #   field_src           = category
        #   method              = lookup_in_ds
        #   field_dst           = categ_code
        # </step>
        subtest 'i. type_lookup_ds' => sub {

        ok my $step = shift @{$trafos_row}, 'the i. lookup step';

        my $records_4i = [
            { category => "Planes",        id => 1 },
            { category => "Trains",        id => 2 },
            { category => "Some unknown ", id => 3 },
            { category => "Planes",        id => 4 },
            { category => "Another cat.",  id => 5 },
        ];

        my @records;
        foreach my $rec ( @{$records_4i} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_lookup( $step, $rec, $logstr );
        }

        my $expected_4i = [
            { category => "Planes",        categ_code => "P",   id => 1 },
            { category => "Trains",        categ_code => "T",   id => 2 },
            { category => "Some unknown ", categ_code => "Some unknown ", id => 3 },
            { category => "Planes",        categ_code => "P",   id => 4 },
            { category => "Another cat.",  categ_code => "Another cat.", id => 5 },
        ];

        is_deeply \@records, $expected_4i, 'i. resulting records';

        };                      # subtest i.


        ######################################################################
        # Test the move_filtered_regex plugin and type_copy trafo method
        # with valid_regex

        # The step config section
        # <step>
        #   type                = copy
        #   valid_regex         = "(\d{4,4}([/;,]\d{4,4})*)"
        #   field_src           = year
        #   method              = move_filtered
        #   field_dst           = obs
        #   attributes          = MOVE | APPENDSRC
        # </step>
        subtest 'j. copy' => sub {

        ok my $step = shift @{$trafos_row}, 'the j. step';

        my $records_4j = [
            { year => "1890",         id => 1, obs => undef },
            { year => "2021",         id => 2, obs => undef },
            { year => "1950/1973",    id => 3, obs => undef },
            { year => "1963",         id => 4, obs => undef },
            { year => "1999",         id => 5, obs => undef },
            { year => "unknown year", id => 6, obs => 'some obs' },
            { year => "i don't know", id => 7, obs => undef },
        ];

        my @records;
        foreach my $rec ( @{$records_4j} ) {
            my $id = $rec->{id} // '?';
            my $logstr = "[id:$id]";
            push @records, $trafo->type_copy( $step, $rec, $logstr );
        }

        my $expected_4j = [
            { id => 1, year => "1890",      obs => undef },
            { id => 2, year => "2021",      obs => undef },
            { id => 3, year => "1950/1973", obs => undef },
            { id => 4, year => "1963",      obs => undef },
            { id => 5, year => "1999",      obs => undef },
            { id => 6, year => undef, obs => "some obs, year: unknown year" },
            { id => 7, year => undef, obs => "year: i don't know" },
        ];

        cmp_deeply \@records, $expected_4j, 'j. resulting records';

        };                      # subtest j.


        ######################################################################
        # All done.
        done_testing;
    };
}

1;

=encoding utf8

=head1 DESCRIPTION

Database test module adapted an adopted from Sqitch.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

Stefan Suciu <stefan@s2i2.ro>

=head1 LICENSE

Copyright (c) 2012-2013 iovation Inc.

Copyright (c) 2015-2016 Stefan Suciu.

Permission is hereby granted, free of charge, to any person obtaining a copy
of that software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and that permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
