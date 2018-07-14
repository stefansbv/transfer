# Test for the Render module

use 5.010;
use strict;
use warnings;
use Test::Most;
use Path::Tiny;
use Locale::TextDomain 1.20 qw(App-Transfer);
use Locale::Messages qw(bindtextdomain);

bindtextdomain 'App-Transfer' => './.build/latest/share';

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

subtest 'Default name: recipe' => sub {
    my $args = {
        output_path => path( 't', 'output' ),
        tmpl_path   => path( 'share', 'templates' ),
    };

    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    is $atr->get_template, 'recipe.tt', 'template for recipe';

    my $test_file = path 'test-render-recipe.conf';
    my $dest_file = path( $args->{output_path}, $test_file )->stringify;
    is $atr->render( { r => $data }, $test_file ), $dest_file, 'render recipe file';
    unlink $dest_file;
};

subtest 'Template name: bad' => sub {
    my $args = {
        tmpl_name   => 'bad.tt',
        output_path => path( 't', 'output' ),
        tmpl_path   => path( 't' ),
    };

    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    is $atr->get_template, 'bad.tt', 'template for recipe';

    my $recipe_data    = { r => $data };
    my $output_file = path 'test-render-recipe.conf';
    throws_ok { $atr->render($recipe_data, $output_file) } 'App::Transfer::X',
        'should die on bad template';
    is $@->ident, 'render', 'Ident should be render';
    is $@->message, __x( 'Template error: {error}', error => 'file error - bad.tt: not found' ),
        'the message should start with template error';
};

subtest 'Render to string' => sub {
    my $args = {
        tmpl_path  => path( 'share', 'templates' ),
        tmpl_name  => 'datatable',
    };

    my $recipe_data = { r => $data };
    ok my $atr = App::Transfer::Render->new($args), 'render instance';

    is $atr->get_template, 'datatable.tt', 'template for recipe';

    my $output_str = '';
    ok $atr->render_str($recipe_data, \$output_str), 'render recipe file';
    # note $output_str;
    is !$output_str, '', 'has some output';
};

done_testing;
