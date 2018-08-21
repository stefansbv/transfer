use 5.010001;
use utf8;
use Test::Most;
use Test::Log::Log4perl;
use Log::Log4perl;
use Test::Most;
use Test::Moose;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use App::Transfer::Plugin;

BEGIN { Log::Log4perl->init('t/log.conf') }

chdir 't';                          # also load plugins from t/plugins

subtest 'Column Type Transformations' => sub {
    ok my $ttr = App::Transfer::Plugin->new( plugin_type => 'column_type' ),
        'new plugin object';
    meta_ok $ttr, "App::Transfer::Plugin has a 'meta'";
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
        logstr      => 'error',
    };

    #-- Date                                     TODO: test with different date seps

    $p->{value}      = '31.01.2014';
    $p->{src_format} = 'dmy';
    $p->{src_sep}    = '.';
    is $ttr->do_transform( 'date', $p ), '2014-01-31', 'date dmy to iso';

    $p->{value}      = '01/31/2014';
    $p->{src_format} = 'mdy';
    $p->{src_sep}    = '/';
    is $ttr->do_transform( 'date', $p ), '2014-01-31', 'date mdy to iso';

    $p->{value}      = '2014-01-31';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'date', $p ), '2014-01-31', 'date iso to iso';

    $p->{value}      = '2014-12';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'date', $p ), undef, 'date iso to iso incomplete';

    $p->{value}      = undef;
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'date', $p ), undef, 'date iso to iso undef';

    $p->{value}      = '';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'date', $p ), undef, 'date iso to iso empty';

    #-- Date Time                                TODO: test with different date seps

    #-- Firebird timestamp

    $p->{value}      = '31.01.2014, 18:30:34:000';
    $p->{src_format} = 'dmy';
    $p->{src_sep}    = '.';
    is $ttr->do_transform( 'timestamp', $p ), '2014-01-31T18:30:34:000',
        'date dmy to iso';

    $p->{value}      = '01/31/2014T18:30:34:000';
    $p->{src_format} = 'mdy';
    $p->{src_sep}    = '/';
    is $ttr->do_transform( 'timestamp', $p ), '2014-01-31T18:30:34:000',
        'date mdy to iso';

    $p->{value}      = '2014-01-31;18:30:34:000';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'timestamp', $p ), '2014-01-31T18:30:34:000',
        'date iso to iso';

    $p->{value}      = '2014-12';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'timestamp', $p ), undef, 'date iso to iso incomplete';

    $p->{value}      = '';
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'timestamp', $p ), undef, 'date iso to iso empty';

    $p->{value}      = undef;
    $p->{src_format} = 'iso';
    $p->{dst_format} = 'iso';
    is $ttr->do_transform( 'timestamp', $p ), undef, 'date iso to iso undef';

    #-- PostgreSQL timestamp

    $p->{value}      = '2017-05-04 13:02:08.613372';
    $p->{src_format} = 'iso';
    $p->{src_sep}    = '.';
    is $ttr->do_transform( 'timestamp', $p ), '2017-05-04T13:02:08.613372',
        'date dmy to iso';

  TODO: {
        todo_skip "Test log info for plugin: date not date", 1;
        $p->{value} = '2014';
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.date', info => qr/is not a date/ ] );
        $ttr->do_transform( 'date', $p );
    }

  TODO: {
        todo_skip "Test log info for plugin: date not valid", 1;
        $p->{value} = '01/31/2014';
        my $t = Test::Log::Log4perl->expect(
            [   'App.Transfer.Plugin.date',
                info => qr/is not a valid EU date/
            ]
        );
        $ttr->do_transform( 'date', $p );
    }

    @$p{qw(value src_format src_sep)} = ( undef, undef, undef ); # reset

    #-- Integer

    $p->{value} = 2300125;
    is $ttr->do_transform( 'integer', $p ), 2300125, 'integer 2300125';

    $p->{value} = -2300125;
    is $ttr->do_transform( 'integer', $p ), -2300125, 'integer -2300125';

    $p->{value} = 0;
    is $ttr->do_transform( 'integer', $p ), 0, 'integer zero';

    $p->{value} = '';
    is $ttr->do_transform( 'integer', $p ), undef, 'integer undef';

    $p->{value} = undef;
    is $ttr->do_transform( 'integer', $p ), undef, 'integer unef';

    $p->{value} = undef;
    is $ttr->do_transform( 'integer', $p ), undef, 'integer undef';

  TODO: {
        todo_skip "Test log info for plugin: integer not numeric", 1;
        $p->{value} = 'fun';
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.integer', info => qr/is not numeric/ ] );
        $ttr->do_transform( 'integer', $p );
    }

  TODO: {
        todo_skip "Test log info for plugin: integer not numeric", 1;
        $p->{value} = '';
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.integer', info => qr/is not numeric/ ] );
        $ttr->do_transform( 'integer', $p );
    }

    #-- Smallint

    $p->{value} = 2301;
    is $ttr->do_transform( 'smallint', $p ), 2301, 'smallint 2301';

    $p->{value} = 0;
    is $ttr->do_transform( 'smallint', $p ), 0, 'smallint 0';

    $p->{value} = undef;
    is $ttr->do_transform( 'smallint', $p ), undef, 'smallint undef';

    $p->{value} = '';
    is $ttr->do_transform( 'smallint', $p ), undef, 'smallint undef';

    $p->{value} = -32768;
    is $ttr->do_transform( 'smallint', $p ), -32768, 'smallint -limit';

    $p->{value} = 32767;
    is $ttr->do_transform( 'smallint', $p ), 32767, 'smallint +limit';

    $p->{value} = -32769;
    is $ttr->do_transform( 'smallint', $p ), undef, 'small smallint outside of range';

    $p->{value} = 32768;
    is $ttr->do_transform( 'smallint', $p ), undef, 'small smallint outside of range';

  TODO: {
        todo_skip "Test log info for plugin: smallint ouside of range", 1;
        $p->{value} = -32769;
        my $t
            = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.smallint', info => qr/outside of range/ ]
            );
        $ttr->do_transform( 'smallint', $p );
    }

    $p->{value} = 32767;
    is $ttr->do_transform( 'smallint', $p ), 32767, 'big smallint';

  TODO: {
        todo_skip "Test log info for plugin: smallint ouside of range", 1;
        $p->{value} = 32768;
        my $t
            = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.smallint', info => qr/outside of range/ ]
            );
        $ttr->do_transform( 'smallint', $p );
    }

    #-- Numeric

    @$p{qw(value prec scale)} = ( "1,000.01", 8, 2 );
    is $ttr->do_transform( 'numeric', $p ), 1000.01, 'numeric 1,000.01';

    @$p{qw(value prec scale)} = ( 1720.00, 8, 2 );
    is $ttr->do_transform( 'numeric', $p ), 1720, 'numeric 1720.00';

    @$p{qw(value prec scale)} = ( 51720.100, 8, 2 );
    is $ttr->do_transform( 'numeric', $p ), 51720.1, 'numeric 51720.100';

    @$p{qw(value prec scale)} = ( 0.123, 8, 2 );
    is $ttr->do_transform( 'numeric', $p ), 0.123, 'numeric 0.123';

    @$p{qw(value prec scale)} = ( undef, 8, 2 );
    is $ttr->do_transform( 'numeric', $p ), undef, 'numeric undef';

    @$p{qw(value prec scale)} = ( '', 8, 2 );
  TODO: {
        todo_skip "Test log info for plugin: numeric empty string", 1;
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.numeric', info => qr/is not numeric/ ] );
        $ttr->do_transform( 'numeric', $p );
    }
    is $ttr->do_transform( 'numeric', $p ), undef,
        'numeric empty string return undef';

    @$p{qw(value prec scale)} = ( 'fun', 8, 2 );
  TODO: {
        todo_skip "Test log info for plugin: numeric string", 1;
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.numeric', info => qr/is not numeric/ ] );
        $ttr->do_transform( 'numeric', $p );
    }
    is $ttr->do_transform( 'numeric', $p ), undef,
        'numeric string returns undef';

    @$p{qw(value prec scale)} = ( undef, undef, undef ); # reset

    #-- Char

    @$p{qw(value length)} = ( "a char field", 12 );
    is $ttr->do_transform( 'char', $p ), "a char field", 'char text';

    @$p{qw(value length)} = ( "", 12 );
    is $ttr->do_transform( 'char', $p ), undef, 'char text ""';

    @$p{qw(value length)} = ( undef, 12 );
    is $ttr->do_transform( 'char', $p ), undef, 'char text undef';

  TODO: {
        todo_skip "Test log info for plugin: char", 1;
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.char', info => qr/overflow/ ] );
        @$p{qw(value length)} = ( "a char field", 2 );
        $ttr->do_transform( 'char', $p );
    }

    #-- Varchar

  TODO: {
        todo_skip "Test log info for plugin: varchar", 1;
        my $t = Test::Log::Log4perl->expect(
            [ 'App.Transfer.Plugin.char', info => qr/overflow/ ] );
        @$p{qw(value length)} = ( "a varchar field", 2 );
        $ttr->do_transform( 'varchar', $p );
    }

    @$p{qw(value length)} = ( "", 12 );
    is $ttr->do_transform( 'varchar', $p ), undef, 'varchar text ""';

    @$p{qw(value length)} = ( undef, 12 );
    is $ttr->do_transform( 'varchar', $p ), undef, 'varchar text undef';

    @$p{qw(value length)} = ( "ro_RO şţâăî", 15 );
    is $ttr->do_transform( 'varchar', $p ), "ro_RO șțâăî",
        'varchar translit test';
};

subtest 'Column Transformations' => sub {
    ok my $ttr = App::Transfer::Plugin->new( plugin_type => 'column' ),
        'new plugin object';
    meta_ok $ttr, "App::Transfer::Plugin has a 'meta'";
    has_attribute_ok $ttr, 'plugins', '"plugins"';

    my $p = {
        name   => 'field',
        logstr => 'error',
    };

    #-- First upper character
    $p->{value} = 'da';
    is $ttr->do_transform( 'first_upper', $p ), 'D', 'first_upper string';

    $p->{value} = '';
    is $ttr->do_transform( 'first_upper', $p ), undef,
        'first_upper empty string';

    $p->{value} = undef;
    is $ttr->do_transform( 'first_upper', $p ), undef, 'first_upper undef';

    #-- No space
    $p->{value} = 'da  da da';
    is $ttr->do_transform( 'no_space', $p ), 'dadada', 'no_space string';

    $p->{value} = undef;
    is $ttr->do_transform( 'no_space', $p ), undef, 'no_space undef';

    $p->{value} = '';
    is $ttr->do_transform( 'no_space', $p ), undef, 'no_space empty string';

    #-- One space
    $p->{value} = 'da        da da';
    is $ttr->do_transform( 'one_space', $p ), 'da da da', 'one_space string';

    $p->{value} = undef;
    is $ttr->do_transform( 'one_space', $p ), undef, 'one_space undef';

    $p->{value} = '';
    is $ttr->do_transform( 'one_space', $p ), undef, 'one_space empty string';

    #-- Only digits
    $p->{value} = undef;
    is $ttr->do_transform( 'digits_only', $p ), undef, 'digits_only';

    $p->{value} = '12/56T';
    is $ttr->do_transform('digits_only', $p), 1256, 'digits_only';

    #-- Trim
    $p->{value} = ' a string';
    is $ttr->do_transform('trim', $p), 'a string', 'trim string left';

    $p->{value} = ' another string ';
    is $ttr->do_transform('trim', $p), 'another string', 'trim string both';

    $p->{value} = 'one MORE String     ';
    is $ttr->do_transform('trim', $p), 'one MORE String', 'trim string right';

    $p->{value} = undef;
    is $ttr->do_transform('trim', $p), undef, 'trim undef';

    $p->{value} = '';
    is $ttr->do_transform('trim', $p), undef, 'trim empty string';

    #-- Only a number
    $p->{value} = 'Pret 12.56 L E I';
    is $ttr->do_transform( 'number_only', $p ), 12.56, 'number_only';

    $p->{value} = '';
    is $ttr->do_transform( 'number_only', $p ), undef, 'number_only ""';

    $p->{value} = 'Text without number';
    is $ttr->do_transform( 'number_only', $p ), undef, 'number_only "Text"';

    $p->{value} = undef;
    is $ttr->do_transform( 'number_only', $p ), undef, 'number_only undef';

    #-- Null (undef) if 'undef' string
    $p->{value} = '';
    is $ttr->do_transform( 'null_ifundef', $p ), '', 'null_ifundef ""';

    $p->{value} = 'undef';
    is $ttr->do_transform( 'null_ifundef', $p ), undef, 'null_ifundef "undef"';

    $p->{value} = undef;
    is $ttr->do_transform( 'null_ifundef', $p ), undef, 'null_ifundef undef';

    $p->{value} = 'a str';
    is $ttr->do_transform( 'null_ifundef', $p ), 'a str', 'null_ifundef "a str"';

    #-- Null (undef) if zero
    $p->{value} = '';
    is $ttr->do_transform( 'null_ifzero', $p ), '', 'null if zero ""';

    $p->{value} = 0;
    is $ttr->do_transform( 'null_ifzero', $p ), undef, 'null if zero "undef"';

    $p->{value} = undef;
    is $ttr->do_transform( 'null_ifzero', $p ), undef, 'null if zero undef';

    $p->{value} = 'a str';
    is $ttr->do_transform( 'null_ifzero', $p ), 'a str', 'null if zero "a str"';

    #-- Zero if null (undef)
    $p->{value} = '';
    is $ttr->do_transform( 'zero_ifnull', $p ), '', 'zero if null ""';

    $p->{value} = 0;
    is $ttr->do_transform( 'zero_ifnull', $p ), 0, 'zero if null "undef"';

    $p->{value} = undef;
    is $ttr->do_transform( 'zero_ifnull', $p ), 0, 'zero if null undef';

    $p->{value} = 'a str';
    is $ttr->do_transform( 'zero_ifnull', $p ), 'a str', 'zero if null "undef"';

    #-- Test load plugin from local ./plugins dir
  TODO: {
        todo_skip "Test log info for plugin: test_plugin", 1;
        $p->{value} = 'does nothing';
        my $t = Test::Log::Log4perl->expect(
            [   'App.Transfer.Plugin.test_plugin',
                info => qr/test plugin loaded/
            ]
        );
        ok $ttr->do_transform( 'test_plugin', $p );
    }

    #-- Non existent plugin
    throws_ok { $ttr->do_transform( 'nosuchplugin', $p ) } qr/nosuchplugin/,
        "No plugin for 'nosuchplugin' in 'do_transform'";
};

subtest 'Row Transformations' => sub {
    ok my $ttr = App::Transfer::Plugin->new( plugin_type => 'row' ),
        'new plugin object';
    meta_ok $ttr, "App::Transfer::Plugin has a 'meta'";
    has_attribute_ok $ttr, 'plugins', '"plugins"';

    my $values_aref = [ 'Brașov', 'B-dul Saturn', 'nr. 20' ];

    #-- join
    my $p = {
        name   => 'field',
        logstr => 'error',
    };

    @$p{qw(values_aref separator)} = ( $values_aref, ', ' );
    ok my $joined = $ttr->do_transform( 'join_fields', $p ), 'join fields';
    is $joined, 'Brașov, B-dul Saturn, nr. 20', 'resulting string';

    #-- split
    $p = {
        name   => 'field',
        logstr => 'error',
    };

    my $value = 'Brașov, B-dul Saturn, nr. 20';
    @$p{qw(value limit separator)} = ( $value, 3, ',' );
    ok my @splited = $ttr->do_transform( 'split_field', $p ), 'split field';
    cmp_deeply \@splited, $values_aref, 'resulting values';
};

subtest 'Unknown plugin type' => sub {
    throws_ok {
        App::Transfer::Plugin->new( plugin_type => 'unknown' ),
              'new plugin object';
    } qr/Attribute \(plugin_type\) does not pass/,
        'should get plugin_type exception';
};

subtest 'Old plugin in plugin base dir' => sub {
    my $method = 'old_plugin';
    ok my $ttr = App::Transfer::Plugin->new( plugin_type => 'row' ),
        'new plugin object';
    my $found = 0;
    for my $plugin ( @{ $ttr->plugins } ) {
        if ( $plugin->can($method) ) {
            $found = 1;
        }
    }
    ok !$found, 'old_plugin not supposed to be found';
};

done_testing;
