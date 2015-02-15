#
# Test the application commands, parameters and options
#
use 5.010001;
use strict;
use warnings;
use Test::Most;
use App::Transfer;

# Command: run

subtest 'Command "run" with full options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(run --dryrun --verbose --if t/siruta.xls t/recipes/recipe-xls.conf)] );
    my $app = App::Transfer->new_with_command();
    isa_ok( $app, 'App::Transfer::Command::run' );
    is( $app->dryrun, 1, 'Option "--dryrun" is set' );
    is( $app->verbose, 1, 'Option "--verbose" is set' );
    is( $app->input_file, 't/siruta.xls', 'Option "--if" is set' );
    is( $app->recipe, 't/recipes/recipe-xls.conf', 'Option "--recipe" is set' );
};

subtest 'Command "run" without optional options' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(run --if t/siruta.xls t/recipes/recipe-xls.conf)]);
    my $app = App::Transfer->new_with_command();
    isa_ok($app, 'App::Transfer::Command::run');
    is( $app->dryrun, undef, 'Option "--dryrun" is not set' );
    is( $app->verbose, undef, 'Option "--verbose" is not set' );
    is( $app->input_file, 't/siruta.xls', 'Option "--if" is set' );
    is( $app->recipe, 't/recipes/recipe-xls.conf', 'Option "--recipe" is set' );
};

subtest 'Command "run" without options' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(run --if t/siruta.xls t/recipes/recipe-xls.conf)]);
    my $app = App::Transfer->new_with_command();
    isa_ok($app, 'App::Transfer::Command::run');
    is( $app->dryrun, undef, 'Option "--dryrun" is not set' );
    is( $app->verbose, undef, 'Option "--verbose" is not set' );
    is( $app->input_file, 't/siruta.xls', 'Option "--if" is set' );
    is( $app->recipe, 't/recipes/recipe-xls.conf', 'Option "--recipe" is set' );
};

subtest 'Command "run" without options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(run)] );
    my $app = App::Transfer->new_with_command();
    isa_ok( $app, 'MooseX::App::Message::Envelope' );
    is( $app->blocks->[0]->type, "error", 'Message is of type error' );
    is( $app->blocks->[0]->header,
        "Required parameter 'recipe' missing",
        'Message 1 is set'
    );
    is( $app->blocks->[1]->header,
        "usage:",
        'Usage message'
    );
};

done_testing;
