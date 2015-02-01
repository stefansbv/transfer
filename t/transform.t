use 5.010;
use Test::Most;
use Log::Log4perl;
use Test::Moose;

use App::Transfer::Transform;

BEGIN { Log::Log4perl->init('t/log.conf') }

chdir 't';                          # also load plugins from t/plugins
ok my $ttr = App::Transfer::Transform->new, 'New Transform object';
meta_ok $ttr, "App::Transfer::Transform has a 'meta'";
has_attribute_ok $ttr, 'plugins', '"plugins"';

my $p = {
    pos         => 0,
    name        => 'field',
    type        => undef,
    defa        => undef,
    is_nullable => undef,
    length      => undef,
    prec        => undef,
    scale       => undef,
    logfld      => 'logfld',
    logidx      => 'logidx',

};

# Type functions

#-- Date
$p->{value} = '01.01.2014';
is $ttr->do_transform('date', $p), '2014-01-01', 'date';

#-- Integer
$p->{value} = 2300125;
is $ttr->do_transform('integer', $p), 2300125, 'integer 2300125';

$p->{value} = 0;
is $ttr->do_transform('integer', $p), 0, 'integer o';

$p->{value} = undef;
is $ttr->do_transform('integer', $p), undef, 'integer undef';

$p->{value} = 'fun';
is $ttr->do_transform('integer', $p), undef, 'integer string';

$p->{value} = '';
is $ttr->do_transform('integer', $p), undef, 'integer empty string';

#-- Small integer
$p->{value} = 2301;
is $ttr->do_transform('smallint', $p), 2301, 'smallint 2301';

$p->{value} = 0;
is $ttr->do_transform('smallint', $p), 0, 'smallint 0';

$p->{value} = undef;
is $ttr->do_transform('smallint', $p), undef, 'smallint undef';

$p->{value} = 32768;
is $ttr->do_transform('smallint', $p), undef, 'big integer';

$p->{value} = -32769;
is $ttr->do_transform('smallint', $p), undef, 'small integer';

$p->{value} = 32767;
is $ttr->do_transform('smallint', $p), 32767, 'big smallint';

$p->{value} = -32768;
is $ttr->do_transform('smallint', $p), -32768, 'small smallint';

#-- Numeric
@$p{qw(value prec scale)} = ("1,000.01", 8, 2);
is $ttr->do_transform( 'numeric', $p ), 1000.01, 'numeric 1,000.01';

@$p{qw(value prec scale)} = (1720.00, 8, 2);
is $ttr->do_transform( 'numeric', $p ), 1720, 'numeric 1720.00';

@$p{qw(value prec scale)} = (51720.100, 8, 2);
is $ttr->do_transform( 'numeric', $p ), 51720.1, 'numeric 51720.100';

@$p{qw(value prec scale)} = (0.123, 8, 2);
is $ttr->do_transform( 'numeric', $p ), 0.123, 'numeric 0.123';

@$p{qw(value prec scale)} = (undef, 8, 2);
is $ttr->do_transform( 'numeric', $p ), undef, 'numeric undef';

@$p{qw(value prec scale)} = ('', 8, 2);
is $ttr->do_transform( 'numeric', $p ), undef, 'numeric empty string';

@$p{qw(value prec scale)} = ('fun', 8, 2);
is $ttr->do_transform( 'numeric', $p ), undef, 'numeric string';

#-  Other functions

#-- First upper character
$p->{value} = 'da';
is $ttr->do_transform('first_upper', $p), 'D', 'first_upper string';

$p->{value} = '';
is $ttr->do_transform('first_upper', $p), undef, 'first_upper empty string';

$p->{value} = undef;
is $ttr->do_transform('first_upper', $p), undef, 'first_upper undef';

#-- No space
$p->{value} = 'da  da da';
is $ttr->do_transform('no_space', $p), 'dadada', 'no_space string';

$p->{value} = undef;
is $ttr->do_transform('no_space', $p), undef, 'no_space undef';

$p->{value} = '';
is $ttr->do_transform('no_space', $p), undef, 'no_space empty string';

#-- Only digits
$p->{value} = '12/56T';
is $ttr->do_transform('digits_only', $p), 1256, 'digits_only';

#-- Only a number
$p->{value} = 'Pret 12.56 L E I';
is $ttr->do_transform('number_only', $p), 12.56, 'number_only';

#-- Ro CNP
TODO: {
    todo_skip "How to test log info output?", 1;
    $p->{value} = '1234567890123';
    throws_ok { $ttr->do_transform( 'ro_cnp', $p ) } qr/birthday/,
        'Wrong date at reader Business::RO::CNP::birthday';
}

#-- Test load plugin from local ./plugins dir
$p->{value} = 'does nothing';
is $ttr->do_transform('test_plugin', $p), 'does nothing', 'test plugin';

#-- Non existent plugin
throws_ok { $ttr->do_transform('nosuchplugin', $p) } qr/nosuchplugin/, "No plugin for 'nosuchplugin' in 'do_transform'";

done_testing;
