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
#use File::Temp 'tempdir';

use Data::Printer;

# Just die on warnings.
use Carp; BEGIN { $SIG{__WARN__} = \&Carp::confess }

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
        is $@->ident, $DBI::state, 'Ident should be SQL error state';
        like $@->message, $p{engine_err_regex}, 'The message should be from the engine';
        like $@->previous_exception, qr/DBD::[^:]+::db do failed: /,
            'The DBI error should be in preview_exception';


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

        my $ddl = qq{CREATE TABLE test_info ( \n   $fields_list \n);};

        ok $engine->dbh->do($ddl), 'create test_info table';

        ok my $info = $engine->get_info('test_info'), 'get info for table';
        foreach my $rec (@fields_info) {
            my ($name, $type) = @{$rec};
            $type =~ s{\(.*\)}{}gmx;       # just the type
            $type =~ s{\s+precision}{}gmx; # just 'double'
            $type =~ s{bigint}{int64}gmx;  # made with 'bigint' but is 'int64'
            is $info->{$name}{type}, $type, "type for field '$name' is '$type'";
        }


        ######################################################################
        # Test the DB reader

        # Change target_params hash ref key from 'uri' to 'input_uri',
        # as required by App::Transfer::Options
        my $target_params = [ 'input_uri', $p{target_params}[1] ];
        my $options_href = {
            @{ $target_params || [] },
        };
        ok $recipe = $transfer->recipe, 'get the recipe object again';
        ok my $options = App::Transfer::Options->new(
            transfer => $transfer,
            options  => $options_href,
            rw_type  => 'reader',
        ), 'options object';
        ok my $reader = App::Transfer::Reader->load({
            transfer => $transfer,
            recipe   => $recipe,
            reader   => 'db',
            options  => $options,
        }), 'new db reader object';

        # Test for failure
        throws_ok { $reader->get_fields('nonexistenttable') } 'App::Transfer::X',
            'Should have error for nonexistent table';
        is $@->ident, 'reader', 'Nonexistent table error ident should be "reader"';
        is $@->message, __(
            'Table "nonexistenttable" does not exists'
        ), 'Nonexistent table error should be correct';

        # Test reader
        ok my $table = $reader->table, 'get the table name';
        is $table, 'test_info', 'check the table name';

        throws_ok { $reader->get_fields($table) }
            qr/\QColumns from the map file not found in the/,
            'Should get an exception for nonexistent columns';

        # ok my $fields = $reader->get_fields($table), 'table fields';
        # is scalar @{$fields}, 6, 'got 6 fields';

        # ok my $records = $reader->get_data, 'get data for table';
        # ok scalar @{$records} > 0, 'got some records';


        ######################################################################
        # All done.
        done_testing;
    };
}

1;
