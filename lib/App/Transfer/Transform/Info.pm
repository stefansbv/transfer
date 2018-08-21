package App::Transfer::Transform::Info;

# ABSTRACT: Transformation info messages

use 5.010001;
use utf8;
use Moose;
use Perl6::Form;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use namespace::autoclean;

sub job_intro {
    my ( $self, %p) = @_;
    my @recipe_ldet =
      ( __ 'version:', __ 'syntax version:', __ 'description:' );
    my @recipe_vdet = ( $p{version}, $p{syntaxversion}, $p{description}, );
    print " -----------------------------\n";
    my $recipe_l = __ 'Recipe:';
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
    $recipe_l, $p{name};
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
      \@recipe_ldet, \@recipe_vdet;
    return;
}

sub job_info_input_file {
    my ($self, $file, $worksheet) = @_;
    my $input_l  = __ 'Input:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $input_l;
    $worksheet //= 'n/a';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;
    return;
}

sub job_info_output_file {
    my ($self, $file, $worksheet) = @_;
    my $output_l = __ 'Output:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $output_l;
    $worksheet //= 'n/a';
    my @i_l = (__ 'file:', __ 'worksheet:');
    my @i_v = ($file, $worksheet);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;
    return;
}

sub job_info_input_db {
    my ($self, $src_table, $src_db) = @_;
    my $input_l  = __ 'Input:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $input_l;
    my @i_l = (__ 'table:', __ 'database:');
    my @i_v = ($src_table, $src_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@i_l,                       \@i_v;
    return;
}

sub job_info_output_db {
    my ($self, $dst_table, $dst_db) = @_;
    my $output_l = __ 'Output:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $output_l;
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($dst_table, $dst_db);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@o_l,                       \@o_v;
    return;
}

sub job_info_prework {
    my $self = shift;
    my $start_l = __ 'Working:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $start_l;
    return;
}

sub job_info_postwork {
    my ($self, $rec_count) = @_;
    $rec_count //= 0;
    my $count_l = __ 'source records read:';
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       $count_l,                    $rec_count;
    return;
}

sub job_summary {
    my ($self, $records_inserted, $records_skipped) = @_;
    my $summ_l = __ 'Summary:';
    print " -----------------------------\n";
    print form
    "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
       $summ_l;
    my @o_l = (__ 'records inserted:', __ 'records skipped:');
    my $ins = $records_inserted // 0;
    my $skp = $records_skipped  // 0;
    my @o_v = ($ins, $skp);
    print form
    "  {]]]]]]]]]]]]]]]]]]]]]]]]]}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
       \@o_l,                       \@o_v;
    print " -----------------------------\n";
    return;
}

1;
