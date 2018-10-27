# Test for the Render module

use 5.010;
use strict;
use warnings;
use Test::Most;
use Path::Tiny;
use Term::ANSIColor qw(color);
use Locale::TextDomain 1.20 qw(App-Transfer);
use Encode;

my $CLASS = 'App::Transfer::Printer::Formatter';
require_ok $CLASS;
can_ok $CLASS => qw(
    new
    formatter
    format
);

isa_ok my $formatter = $CLASS->new, $CLASS, 'Instantiated object';

###############################################################################
# Test all formatting characters.

for my $spec (
    [
    '%7{label}s  %-7{descr}s',
    { label => 'label', descr => 'descr' },
    '  label  descr  ',
    ],
) {
    ( my $desc = encode_utf8 $spec->[2] ) =~ s/\n/[newline]/g;
    local $ENV{ANSI_COLORS_DISABLED} = 1;
    is $formatter->format( $spec->[0], $spec->[1] ), $spec->[2],
        qq{Format "$spec->[0]" should output "$desc"};
}

# Make sure an unknown format character throws a proper exception.
throws_ok { $formatter->format('%Z', {}) } 'App::Transfer::X',
    'Should get an exception for a bad format code';
is $@->ident, 'format',
    'bad format code format error ident should be "log"';
is $@->message, __x(
    'Unknown format code "{code}"', code => 'Z',
), 'bad format code format error message should be correct';

done_testing;
