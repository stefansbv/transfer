use 5.010;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Test::More;
use App::Transfer;
use App::Transfer::Options;
use App::Transfer::Recipe;

my $CLASS;
BEGIN {
    $CLASS = 'App::Transfer::Reader::odt';
    use_ok $CLASS or die;
}

ok my $recipe_file = path( 't', 'recipes', 'recipe-odt.conf' ), "Recipe file";
my $transfer = App::Transfer->new;
my $options_href = {
    input_file => 't/judete.odt',
};
ok my $recipe = App::Transfer::Recipe->new(
    recipe_file => $recipe_file->stringify,
), 'new recipe instance';
my $options = App::Transfer::Options->new(
    transfer => $transfer,
    recipe   => $recipe,
    options  => $options_href,
    rw_type  => 'reader',
);
ok my $reader = App::Transfer::Reader->load({
    transfer => $transfer,
    recipe   => $recipe,
    reader   => 'odt',
    options  => $options,
}), 'new reader odt object';
is $reader->input_file, 't/judete.odt', 'odt file name';
isa_ok $reader->doc, 'ODF::lpOD::Document', 'doc';

ok my @names = $reader->recipe->tables->all_table_names, 'get table name(s)';
my @tables = sort @names;
is_deeply \@tables, [qw{judete}], 'sorted table name(s)';

# my $hcols_j = [ qw{cod_jud denj fsj mnemonic zona} ];
# my @expected_headers = (
#   {
#     headermap => $hcols_j,
#     row       => 0,
#     skip      => 0,
#     table     => "judete",
#     tempfield => undef,
#   },
# );
# ok my @headers = $reader->get_header(0), 'get the header';
# is_deeply \@headers, \@expected_headers, 'header records';

ok my $records = $reader->get_data, 'get data for table';
is scalar @{$records}, 42, 'got 42 records';
is $records->[1]{cod_jud}, 2, 'cod_jud';
is $records->[1]{denj}, "ARAD", 'denj';
is $records->[1]{fsj}, 2, 'fsj';
is $records->[1]{mnemonic}, "AR", 'mnemonic';
is $records->[1]{zona}, 5, 'zona';

done_testing;
