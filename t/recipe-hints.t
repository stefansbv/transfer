#!/usr/bin/env perl

use 5.010;
use utf8;
use Test2::V0;
# use English;

use App::Transfer::Recipe::Hints;

my $records = {
    loc => {
        'SFÂNTU GHEORGHE' => 'Sfîntu Gheorghe',
    },
};

subtest 'hints plain' => sub {
    ok my $h = App::Transfer::Recipe::Hints->new(
        hints => $records,
    );
    is $h->get_hint_for( 'loc', 'sfantu gheorghe' ), undef,
        'lower case, no diacritic';
    is $h->get_hint_for( 'loc', 'SFANTU GHEORGHE' ), undef,
        'upper case, no diacritic';
    is $h->get_hint_for( 'loc', 'Sfantu Gheorghe' ), undef,
        'title case, no diacritic';
    is $h->get_hint_for( 'loc', 'sfântu gheorghe' ), undef,
        'lowercase with diacritic';
    is $h->get_hint_for( 'loc', 'SFÂNTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case with diacritic';
    is $h->get_hint_for( 'loc', 'Sfântu Gheorghe' ), undef,
        'title case with diacritic';
};

subtest 'hints with ignorecase' => sub {
    ok my $h = App::Transfer::Recipe::Hints->new(
        hints      => $records,
        ignorecase => 1,
    );
    is $h->get_hint_for( 'loc', 'sfântu gheorghe' ), 'Sfîntu Gheorghe',
        'lowercase with diacritic';
    is $h->get_hint_for( 'loc', 'SFÂNTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case with diacritic';
    is $h->get_hint_for( 'loc', 'Sfântu Gheorghe' ), 'Sfîntu Gheorghe',
        'title case with diacritic';
};

subtest 'hints with ignorediacritic' => sub {
    ok my $h = App::Transfer::Recipe::Hints->new(
        hints           => $records,
        ignorediacritic => 1,
    );
    is $h->get_hint_for( 'loc', 'sfantu gheorghe' ), undef,
        'lower case, no diacritic';
    is $h->get_hint_for( 'loc', 'SFANTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case, no diacritic';
    is $h->get_hint_for( 'loc', 'Sfantu Gheorghe' ), undef,
        'title case, no diacritic';
    is $h->get_hint_for( 'loc', 'sfântu gheorghe' ), undef,
        'lowercase with diacritic';
    is $h->get_hint_for( 'loc', 'SFÂNTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case with diacritic';
    is $h->get_hint_for( 'loc', 'Sfântu Gheorghe' ), undef,
        'title case with diacritic';
};

subtest 'hints with ignorediacritic and ignorecase' => sub {
    ok my $h = App::Transfer::Recipe::Hints->new(
        hints           => $records,
        ignorediacritic => 1,
        ignorecase      => 1,
    );
    is $h->get_hint_for( 'loc', 'sfantu gheorghe' ), 'Sfîntu Gheorghe',
        'lower case, no diacritic';
    is $h->get_hint_for( 'loc', 'SFANTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case, no diacritic';
    is $h->get_hint_for( 'loc', 'Sfantu Gheorghe' ), 'Sfîntu Gheorghe',
        'title case, no diacritic';
    is $h->get_hint_for( 'loc', 'sfântu gheorghe' ), 'Sfîntu Gheorghe',
        'lowercase with diacritic';
    is $h->get_hint_for( 'loc', 'SFÂNTU GHEORGHE' ), 'Sfîntu Gheorghe',
        'upper case with diacritic';
    is $h->get_hint_for( 'loc', 'Sfântu Gheorghe' ), 'Sfîntu Gheorghe',
        'title case with diacritic';
};

done_testing;
