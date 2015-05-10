#!/usr/bin/perl -w
#
# Made after sqlite.t and mysql.t
#
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Class;
use Try::Tiny;
use Test::Exception;
use Locale::TextDomain qw(App-Transfer);
use File::Spec::Functions;
use File::Temp 'tempdir';
use lib 't/lib';
use DBIEngineTest;

use App::Transfer;
use App::Transfer::Target;
use App::Transfer::Reader;
use App::Transfer::Writer;

my $CLASS;
my $user;
my $pass;
my $tmpdir;
my $have_fb_driver = 1; # assume DBD::Firebird is installed and so is Firebird
my $live_testing   = 0;

# Is DBD::Firebird realy installed?
try { require DBD::Firebird; } catch { $have_fb_driver = 0; };

BEGIN {
    $CLASS = 'App::Transfer::Engine::firebird';
    require_ok $CLASS or die;
    $ENV{TRANSFER_CONFIG}        = 'nonexistent.conf';
    $ENV{TRANSFER_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{TRANSFER_USER_CONFIG}   = 'nonexistent.sys';

    $user = $ENV{ISC_USER}     || $ENV{DBI_USER} || 'SYSDBA';
    $pass = $ENV{ISC_PASSWORD} || $ENV{DBI_PASS} || 'masterkey';

    $tmpdir = File::Spec->tmpdir();

    delete $ENV{ISC_PASSWORD};
}

ok my $recipe_file = file( 't', 'recipes', 'recipe-db.conf' ),
    "Recipe file for db tests";
ok my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
), 'Load a transfer object';
my $target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:firebird:foo.fdb',
);
isa_ok my $fb = $CLASS->new( transfer => $transfer, target => $target ),
    $CLASS;

is $fb->uri->dbname, file('foo.fdb'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

END {
    return unless $live_testing;
    return unless $have_fb_driver;

    foreach my $dbname (qw{__transfertest__}) {
        my $dbpath = catfile($tmpdir, $dbname);
        next unless -f $dbpath;
        my $dsn = qq{dbi:Firebird:dbname=$dbpath;host=localhost;port=3050};
        $dsn .= q{;ib_dialect=3;ib_charset=UTF8};

        my $dbh = DBI->connect(
            $dsn, $user, $pass,
            {   FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 0,
                PrintError       => 0,
            }
        ) or die $DBI::errstr;

        $dbh->{Driver}->visit_child_handles(
            sub {
                my $h = shift;
                $h->disconnect
                    if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
            }
        );

        my $res = $dbh->selectall_arrayref(
            q{ SELECT MON$USER FROM MON$ATTACHMENTS }
        );
        if (@{$res} > 1) {
            # Do we have more than 1 active connections?
            warn "    Another active connection detected, can't DROP DATABASE!\n";
        }
        else {
            $dbh->func('ib_drop_database')
                or warn
                "Error dropping test database '$dbname': $DBI::errstr";
        }
    }
}

my $dbpath = catfile($tmpdir, '__transfertest__');
my $err = try {
    $fb->use_driver;
    DBD::Firebird->create_database(
        {   db_path       => $dbpath,
            user          => $user,
            password      => $pass,
            character_set => 'UTF8',
        }
    );
    undef;
}
catch {
    eval { $_->message } || $_;
};

my $uri = "db:firebird://$user:$pass\@localhost/$dbpath";
DBIEngineTest->run(
    class           => $CLASS,
    trafo_params  => [ recipe_file => $recipe_file, ],
    target_params => [ uri => $uri ],
    skip_unless => sub {
        my $self = shift;
        die $err if $err;
        return 0 unless $have_fb_driver;    # skip if no DBD::Firebird
        $live_testing = 1;
    },
    engine_err_regex => qr/\QDynamic SQL Error\E/xms,
    test_dbh         => sub {
        my $dbh = shift;

        # Check the session configuration...
    },
);

done_testing;
