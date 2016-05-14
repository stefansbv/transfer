use 5.010;
use strict;
use warnings;

use Path::Tiny;
use Test::Most;
use Test::Exception;

use App::Transfer;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Options';
    use_ok $CLASS or die;
}

# Reader

subtest '"db" reader: no options; no config; all from recipe config' => sub {
    my $recipe_file = path( 't', 'recipes', 'recipe4options-4.conf' );
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {}, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name1',
        'should get uri from the recipe config section';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name1', 'should get name from the config';
};

subtest '"db" reader: no options; name, uri from config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {}, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name1',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name1', 'should get name from the config';
    chdir '..';
};

subtest '"db" reader: uri option; no config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_uri => 'db:firebird://user:@localhost/name3',
    }, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name3',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'anonim', 'should get name from the config';
    chdir '..';
};

subtest '"db" reader: target option; uri from config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_target => 'name2',
    }, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
    chdir '..';
};

# Writer

subtest '"db" writer: no options; no config; all from recipe config' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe4options-4.conf' ),
        "Recipe file";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {}, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'writer',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the recipe config section';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
};

subtest '"db" writer: no options; name, uri from config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {}, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'writer',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
    chdir '..';
};

subtest '"db" writer: uri option; no config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_uri => 'db:firebird://user:@localhost/name2',
    }, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'writer',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
    chdir '..';
};

subtest '"db" writer: target option; uri from config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path('recipes', 'recipe4options-3.conf' ),
        "Recipe file with minimum config section";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_target => 'name2',
    }, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'writer',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
    chdir '..';
};

subtest '"file" reader: no options; no config; all from recipe config' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls.conf' ),
        "Recipe file";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {}, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    is $options->file, path('t', 'siruta.xls'),
        'should get file from the CLI options';
};

subtest '"file" reader: input_file option; no config; ignore recipe config' => sub {
    ok my $recipe_file = path( 't', 'recipes', 'recipe-xls.conf' ),
        "Recipe file";
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_file => 't/some/other/test.xls',
    }, 'cli options';
    ok my $recipe = App::Transfer::Recipe->new(
        recipe_file => $recipe_file->stringify,
    ), 'new recipe instance';
    ok my $options = $CLASS->new(
        transfer => $transfer,
        recipe   => $recipe,
        options  => $cli_options,
        rw_type  => 'reader',
    ), 'new options instance';
    throws_ok { $options->file, path('t', 'some', 'other', 'test.xls') } qr/was not found/,
        'should get file not found exception';
};

done_testing;
