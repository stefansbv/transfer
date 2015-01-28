#!/bin/env perl

use Test::More;

use_ok( 'App::Transfer' );
use_ok( 'App::Transfer::X' );
use_ok( 'App::Transfer::Config' );
use_ok( 'App::Transfer::Config::Load' );
use_ok( 'App::Transfer::Recipe' );
use_ok( 'App::Transfer::Recipe::Dst' );
use_ok( 'App::Transfer::Recipe::Types' );
use_ok( 'App::Transfer::Recipe::Table' );
use_ok( 'App::Transfer::Recipe::Transform::Types' );
use_ok( 'App::Transfer::Recipe::Transform::Col::Step' );
use_ok( 'App::Transfer::Recipe::Transform::Row::Step' );
use_ok( 'App::Transfer::Recipe::Header' );
use_ok( 'App::Transfer::Recipe::Load' );
use_ok( 'App::Transfer::Recipe::Datasource' );
use_ok( 'App::Transfer::Recipe::Src' );
use_ok( 'App::Transfer::Recipe::Transform' );
use_ok( 'App::Transfer::Recipe::Table::HeaderMap' );
use_ok( 'App::Transfer::Role::DBIEngine' );
use_ok( 'App::Transfer::Role::Utils' );
use_ok( 'App::Transfer::Command::run' );
use_ok( 'App::Transfer::Engine' );
use_ok( 'App::Transfer::Reader' );
use_ok( 'App::Transfer::Reader::db' );
use_ok( 'App::Transfer::Reader::excel' );
use_ok( 'App::Transfer::Reader::csv' );
use_ok( 'App::Transfer::Writer' );
use_ok( 'App::Transfer::Writer::db' );
use_ok( 'App::Transfer::Engine::pg' );
use_ok( 'App::Transfer::Engine::firebird' );
use_ok( 'App::Transfer::Transform' );

done_testing;
