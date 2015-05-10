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
my $have_fb_driver = 1; # assume DBD::Pg is installed and so is Pg
my $live_testing   = 0;

# Is DBD::Pg realy installed?
try { require DBD::Pg; } catch { $have_fb_driver = 0; };

BEGIN {
    $CLASS = 'App::Transfer::Engine::pg';
    require_ok $CLASS or die;
    $ENV{TRANSFER_CONFIG}        = 'nonexistent.conf';
    $ENV{TRANSFER_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{TRANSFER_USER_CONFIG}   = 'nonexistent.sys';
    delete $ENV{PGPASSWORD};
}

ok my $recipe_file = file( 't', 'recipes', 'recipe-db.conf' ), "Recipe file";
ok my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
), 'Load a transfer object';
my $target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:pg:foo.fdb',
);
isa_ok my $pg = $CLASS->new( transfer => $transfer, target => $target ),
    $CLASS;

is $pg->uri->dbname, file('foo.fdb'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

my $dbh;
END {
    return unless $dbh;
    $dbh->{Driver}->visit_child_handles(sub {
        my $h = shift;
        $h->disconnect if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
    });

    $dbh->do('DROP DATABASE __transfertest__') if $dbh->{Active};
}

my $err = try {
    $pg->use_driver;
    $dbh = DBI->connect('dbi:Pg:dbname=template1', 'postgres', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
    });
    $dbh->do($_) for (
        'CREATE DATABASE __transfertest__',
        q{ALTER DATABASE __transfertest__ SET lc_messages = 'C'},
    );
    undef;
}
catch {
    eval { $_->message } || $_;
};

my $uri = 'db:pg://@localhost/__transfertest__';
DBIEngineTest->run(
    class           => $CLASS,
    trafo_params  => [ recipe_file => $recipe_file, ],
    target_params   => [ uri => $uri ],
    skip_unless     => sub {
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
