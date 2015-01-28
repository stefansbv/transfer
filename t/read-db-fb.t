use 5.010;
use strict;
use warnings;
use utf8;

use Path::Class;
use Test::More;
use Test::Exception;
use Locale::TextDomain qw(App-Transfer);
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Reader::db';
    use_ok $CLASS or die;
}

ok my $recipe_file = file( 't', 'recipes', 'recipe-db.conf' ), "Recipe file";
my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
);
my $options_href = {
    input_uri => 'db:firebird://localhost//home/fbdb/siruta.fdb',
};
my $options = App::Transfer::Options->new(
    transfer => $transfer,
    options  => $options_href,
    rw_type  => 'reader',
);
ok my $recipe = $transfer->recipe, 'has recipe';
ok my $reader = App::Transfer::Reader->load({
    transfer => $transfer,
    recipe   => $recipe,
    reader   => 'db',
    options  => $options,
}), 'new db object';

# Test for failure - borrowed from Sqitch
throws_ok { $reader->get_fields('nonexistenttable') } 'App::Transfer::X',
    'Should have error for nonexistent table';
is $@->ident, 'reader', 'Nonexistent table error ident should be "reader"';
is $@->message, __(
    'Table "nonexistenttable" does not exists'
), 'Nonexistent table error should be correct';

ok my $table = $reader->table, 'get the table name';
is $table, 'siruta', 'the table name';

ok my $fields = $reader->get_fields($table), 'table fields';
is scalar @{$fields}, 7, 'got 7 fields';

ok my $records = $reader->get_data, 'get data for table';
ok scalar @{$records} > 0, 'got some records';

done_testing;
