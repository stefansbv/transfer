#
# Borrowed and adapted from Sqitch v0.997 by @theory
#
use strict;
use warnings;
use 5.010;
use utf8;
use Test::More;
use Path::Class;
use Test::Exception;
use Test::MockModule;
use Locale::TextDomain qw(App-Transfer);
use App::Transfer;
use App::Transfer::Target;
use App::Transfer::X qw(hurl);
use lib 't/lib';

my $CLASS;

BEGIN {
    $CLASS = 'App::Transfer::Engine';
    use_ok $CLASS or die;
    $ENV{TRANSFER_CONFIG} = 'nonexistent.conf';
}

can_ok $CLASS, qw(load new name uri);
my $die = '';
ENGINE: {
    # Stub out a engine.
    package App::Transfer::Engine::whu;
    use Moose;
    use App::Transfer::X qw(hurl);
    extends 'App::Transfer::Engine';
    $INC{'App/Transfer/Engine/whu.pm'} = __FILE__;

    my @SEEN;
    for my $meth (qw(
        get_info
    )) {
        no strict 'refs';
        *$meth = sub {
            hurl 'AAAH!' if $die eq $meth;
            push @SEEN => [ $meth => $_[1] ];
        };
    }

    sub seen { [@SEEN] }
    after seen => sub { @SEEN = () };
}

ok my $recipe_file = file( 't', 'recipes', 'recipe.conf' ), "Recipe file";
my $transfer = App::Transfer->new(
    recipe_file => $recipe_file->stringify,
);

my $mock_engine = Test::MockModule->new($CLASS);

##############################################################################
# Test new().
ok my $target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:firebird:',
), 'new target instance';

my $array = [];
throws_ok { $CLASS->new({ transfer => $array, target => $target }) }
    qr/\QValidation failed for 'App::Transfer' with value/,
    'Should get an exception for array transfer param';
throws_ok { $CLASS->new({ transfer => 'foo', target => $target  }) }
    qr/\QValidation failed for 'App::Transfer' with value/,
    'Should get an exception for string transfer param';
throws_ok { $CLASS->new( transfer => $transfer ) }
    qr/\QAttribute (target) is required/,
    'Should get an exception for missing target param';
throws_ok { $CLASS->new( target => $target ) }
    qr/\QAttribute (transfer) is required/,
    'Should get an exception for missing transfer param';

isa_ok $CLASS->new( { transfer => $transfer, target => $target } ), $CLASS,
    'Engine';

##############################################################################
# Test load().
ok $target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:whu:',
), 'new whu atrget';
ok my $engine = $CLASS->load({
    transfer => $transfer,
    target   => $target,
}), 'Load a "whu" engine';
isa_ok $engine, 'App::Transfer::Engine::whu';
is $engine->transfer, $transfer, 'The transfer attribute should be set';

# Try an unknown engine.
$target = App::Transfer::Target->new(
    transfer => $transfer,
    uri      => 'db:nonexistent:',
);
throws_ok { $CLASS->load( { transfer => $transfer, target => $target } ) }
    'App::Transfer::X', 'Should get error for unsupported engine';
is $@->message, 'Unable to load App::Transfer::Engine::nonexistent',
    'Should get load error message';
like $@->previous_exception, qr/\QCan't locate/,
    'Should have relevant previoius exception';

# Test handling of an invalid engine.
throws_ok { $CLASS->load({ engine => 'nonexistent', transfer => $transfer, target => $target }) }
    'App::Transfer::X', 'Should die on invalid engine';
is $@->message, __('Unable to load App::Transfer::Engine::nonexistent'),
    'Should get load error message';
like $@->previous_exception, qr/\QCan't locate/,
    'Should have relevant previoius exception';

NOENGINE: {
    # Test handling of no target.
    throws_ok { $CLASS->load({ transfer => $transfer }) } 'App::Transfer::X',
            'No target should die';
    is $@->message, 'Missing "target" parameter to load()',
        'It should be the expected message';
}

done_testing;
