#!/usr/bin/perl -w
#
# To test against a live Firebird database, you must set the FBSQL_URI environment variable.
# this is a stanard URI::db URI, and should look something like this:
#
#     export FBSQL_URI=db:fbodbc://user:pass@localhost:3050//path/to//test.fdb?Driver=Firebird
#
# Note that it must include the `?Driver=$driver` bit so that DBD::ODBC loads
# the proper driver.  Alternatively use  `export DBI_DRIVER=Firebird`

# Implmentation inspired/copied from the Sqitch Vertica driver by theory.
#
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Tiny;
use Try::Tiny;
use Test::Exception;
use Locale::TextDomain qw(App-Transfer);
use lib 't/lib';
use DBIEngineTest;

use App::Transfer;
use App::Transfer::Target;
use App::Transfer::Reader;
use App::Transfer::Writer;

my $CLASS;
my $have_odbc_driver = 1;     # assume DBD::ODBC is installed and so is ODBC
my $live_testing   = 0;

# Is DBD::ODBC realy installed?
try { require DBD::ODBC; } catch { $have_odbc_driver = 0; };

BEGIN {
    $CLASS = 'App::Transfer::Engine::fbodbc';
    require_ok $CLASS or die;
    $ENV{TRANSFER_CONFIG}        = 'nonexistent.conf';
    $ENV{TRANSFER_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{TRANSFER_USER_CONFIG}   = 'nonexistent.sys';
}

ok my $recipe_file = path( 't', 'recipes', 'recipe-db.conf' ), "Recipe file";
ok my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
), 'Load a transfer object';
my $target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:ODBC:foo.fdb',
);
isa_ok my $ofb = $CLASS->new( transfer => $transfer, target => $target ),
    $CLASS;

is $ofb->uri->dbname, path('foo.fdb'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?
my $dbh;
END {
    return unless $dbh;
    $dbh->{Driver}->visit_child_handles(sub {
        my $h = shift;
        $h->disconnect if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
    });

    $dbh->{RaiseError} = 0;
    $dbh->{PrintError} = 1;
    $dbh->do($_) for (
        'DROP TABLE test_db',
        'DROP TABLE test_dict',
        'DROP TABLE test_import',
        'DROP TABLE test_info',
    );
}

my $uri = URI->new($ENV{FBSQL_URI} || 'db:fbodbc://user:@localhost/dbname');
my $err = try {
    $ofb->use_driver;
    $dbh = DBI->connect($uri->dbi_dsn, $uri->user, $uri->password, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
    });
    undef;
}
catch {
    eval { $_->message } || $_;
};

DBIEngineTest->run(
    class         => $CLASS,
    trafo_params  => [ recipe_file => $recipe_file, ],
    target_params => [ uri => $uri ],
    skip_unless   => sub {
        my $self = shift;
        die $err if $err;
        1;
    },
    engine_err_regex => qr/^ERROR:  /,
    test_dbh         => sub {
        my $dbh = shift;
    },
);

done_testing;
