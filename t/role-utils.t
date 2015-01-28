#
# Test the Utils role
#
use 5.010;
use strict;
use warnings;
use Path::Tiny;
use File::HomeDir;

use Test::Most;
use Test::Moose;
use MooseX::ClassCompositor;

use App::Transfer;
use App::Transfer::Role::Utils;

my @attributes = ( qw() );
my @methods    = ( qw(sort_hash_by_pos trim) );

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::Transfer::Role::Utils', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
)} 'Test creation of an instance';

done_testing;

# end
