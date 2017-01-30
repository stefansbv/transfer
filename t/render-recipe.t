# Test for the Render module

use 5.010;
use strict;
use warnings;
use Test::Most;
use Path::Tiny;

use_ok('App::Transfer::Render');

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

subtest 'Unknown type' => sub {
    my $args = {
        type        => 'unknown',
        recipe_data => { r => $data },
        output_file => 'test-render-recipe.conf',
        output_path => path( 't', 'output' ),
        templ_path  => path( 'share', 'templates' ),
    };

    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    throws_ok { $atr->get_template } 'App::Transfer::X',
        'should die on unknown template type';
};

subtest 'Undefined type' => sub {
    my $args = {
        type        => '',
        recipe_data => { r => $data },
        output_file => 'test-render-recipe.conf',
        output_path => path( 't', 'output' ),
        templ_path  => path( 'share', 'templates' ),
    };

    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    throws_ok { $atr->get_template } 'App::Transfer::X',
        'should die on unknown template type';
};

subtest 'Default type: recipe' => sub {
    my $args = {
        recipe_data => { r => $data },
        output_file => 'test-render-recipe.conf',
        output_path => path( 't', 'output' ),
        templ_path  => path( 'share', 'templates' ),
    };

    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    is $atr->get_template, 'recipe.tt', 'template for recipe';

    is $atr->render, path( $args->{output_path}, $args->{output_file} )->stringify,
        'render recipe file';
};

done_testing;
