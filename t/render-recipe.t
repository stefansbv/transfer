# Test for the Render module

use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Tiny;

use_ok('App::Transfer::Render');

is( App::Transfer::Render->get_template_for('recipe'),
    'recipe.tt', 'template for recipe' );

dies_ok { Tpda3::Devel::Render->get_template_for('fail-test') };

my $data = {
    copy_author => 'user_name',
    copy_email  => 'user_email',
    copy_year   => (localtime)[5] + 1900,
    columns     => [qw {field1 field2 field3}],
    reader      => 'db',
    writer      => 'db',
    src_target  => 'input_target',
    dst_target  => 'output_target',
    src_table   => 'src_table',
    dst_table   => 'dst_table',
    order_field => 'field',
};

my $args = {
    type        => 'recipe',
    output_file => 'test-render-recipe.conf',
    data        => { r => $data },
    output_path => path('t', 'output'),
    templ_path  => path( 'share', 'templates' ),
};

ok( App::Transfer::Render->new->render($args), 'render recipe file' );

done_testing;
