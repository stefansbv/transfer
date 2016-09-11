#
# Borrowed and adapted from Sqitch v0.997 by @theory
#
use strict;
use warnings;
use Test::More;
use File::Spec;
use Test::MockModule;
use Test::Exception;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Config';
    use_ok $CLASS or die;
}

# Protect against user's environment variables
delete @ENV{qw( TRANSFER_CONFIG TRANSFER_USER_CONFIG TRANSFER_SYSTEM_CONFIG )};

isa_ok my $config = $CLASS->new, $CLASS, 'New config object';
is $config->confname, 'transfer.conf', 'confname should be "transfer.conf"';

is $config->user_dir, File::Spec->catfile(
    File::HomeDir->my_home, '.transfer'
), 'Default user directory should be correct';

is $config->global_file, File::Spec->catfile(
    $config->system_dir, 'transfer.conf'
), 'Default global file name should be correct';

my $file = File::Spec->catfile(qw(FOO BAR));
$ENV{TRANSFER_SYSTEM_CONFIG} = $file;
is $config->global_file, $file,
    'Should preferably get TRANSFER_SYSTEM_CONFIG file from global_file';
is $config->system_file, $config->global_file, 'system_file should alias global_file';

is $config->user_file, File::Spec->catfile(
    File::HomeDir->my_home, '.transfer', 'transfer.conf'
), 'Default user file name should be correct';

$ENV{TRANSFER_USER_CONFIG} = $file,
is $config->user_file, $file,
    'Should preferably get TRANSFER_USER_CONFIG file from user_file';

is $config->local_file, 'transfer.conf',
    'Local file should be correct';
is $config->dir_file, $config->local_file, 'dir_file should alias local_file';

TRANSFER_CONFIG: {
    local $ENV{TRANSFER_CONFIG} = 'transfer.ini';
    is $config->local_file, 'transfer.ini', 'local_file should prefer $TRANSFER_CONFIG';
    is $config->dir_file, 'transfer.ini', 'And so should dir_file';
}

chdir 't';
is_deeply $config->get_section(section => 'user'), {
    name => "Stefan Suciu",
}, 'get_section("user") should work';

is_deeply $config->get_section(section => 'source'), {
    reader => 'db',
    target => 'name1',
    table  => 'table',
}, 'get_section("source") should work';

is_deeply $config->get_section(section => 'destination'), {
    writer => 'db',
    target => 'name2',
    table  => 'table',
}, 'get_section("destination") should work';

is_deeply $config->get_section(section => 'target.name1'), {
    uri => 'db:firebird://user:@localhost/name1'
}, 'get_section("target.name1") should work';

is_deeply $config->get_section(section => 'target.name2'), {
    uri => 'db:firebird://user:@localhost/name2'
}, 'get_section("target.name2") should work';

like $config->sharedir, qr/share/, 'sharedir';
like $config->templ_path, qr/templates/, 'templates';

done_testing;
