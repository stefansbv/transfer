use 5.010;
use strict;
use warnings;
use Path::Tiny;
use Test::Most;
use Locale::TextDomain 1.20 qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

use App::Transfer;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Options';
    use_ok $CLASS or die;
}

# Reader

subtest '"db" reader: no options; no config; all from recipe config' => sub {
    my $recipe_file = path(qw(t recipes options recipe-4.conf));
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
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
    is $options->_get_uri_from_config('name1'),
        'db:firebird://user:@localhost/name1', 'uri from config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name1', 'should get name from the config';
    chdir '..';
};

subtest '"db" reader: uri option; no config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
    is $options->target, '', 'should get default from the config';
    chdir '..';
};

subtest '"db" reader: target option; uri from config; reader, writer from recipe' => sub {
    chdir 't';
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
    ok my $recipe_file = path(qw(t recipes options recipe-4.conf)),
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
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
    ok my $recipe_file = path(qw(recipes options recipe-3.conf)),
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
        rw_type  => 'writer',
    ), 'new options instance';
    is $options->uri_str, 'db:firebird://user:@localhost/name2',
        'should get uri from the config';

    # Have to call 'target' after 'uri_str', else we get the default
    is $options->target, 'name2', 'should get name from the config';
    chdir '..';
};

subtest '"file" reader: no options; no config; all from recipe config' => sub {
    ok my $recipe_file = path(qw(t recipes recipe-generic.conf)),
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
    ok my $recipe_file = path(qw(t recipes recipe-generic.conf)),
        "Recipe file";
    my $input_file = path qw(t some other test.xls);
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        input_file => $input_file,
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
    throws_ok { $options->file }
        'App::Transfer::X',
      'Should get an exception - not a recipe file';
    is $@->message, __x("The file '{file}' was not found!", file  => $input_file),
        'The message should be from the translation';
    throws_ok { $options->path }
        'App::Transfer::X',
      'Should get an exception - path not a reader option';
    is $@->message, __("Path option not available for the reader"),
        'The message should be from the translation';
};

subtest '"file" reader: output_file option; no config; ignore recipe config' => sub {
    ok my $recipe_file = path(qw(t recipes recipe-db2csv.conf)),
        "Recipe file";
    my $output_file = 'test-output.csv';
    ok my $transfer = App::Transfer->new, 'new transfer instance';
    ok my $cli_options = {
        output_file => $output_file,
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
    is $options->path, path('t', 'output'), 'output path';
};

done_testing;
