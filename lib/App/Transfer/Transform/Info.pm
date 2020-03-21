package App::Transfer::Transform::Info;

# ABSTRACT: Transformation info messages

use 5.010001;
use utf8;
use Moose;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::Printer;
use namespace::autoclean;

has '_printer' => (
    is       => 'ro',
    isa      => 'App::Transfer::Printer',
    lazy     => 1,
    default  => sub { App::Transfer::Printer->new },
    handles  => [ 'printer' ],
);

sub job_intro {
    my ( $self, %p) = @_;
    my $recipe_l = __ 'Recipe:';
    my $recipe_v = $p{name};
    my @r_l = ( __ 'version:', __ 'syntax version:', __ 'description:' );
    my @r_v = ( $p{version}, $p{syntaxversion}, $p{description} );
    print " -----------------------------\n";
    $self->printer( '2i2c_ll', { label => $recipe_l, descr => $recipe_v } );
    foreach my $i ( 0..2 ) {
        $self->printer( '0i2c_rl', { label => $r_l[$i], descr => $r_v[$i] } );
    }
    return;
}

sub job_info_input_file {
    my ($self, $file, $worksheet) = @_;
    $worksheet //= 'n/a';
    my $input_l  = __ 'Input:';
    my @i_l = ( __ 'file:', __ 'worksheet:' );
    my @i_v = ( $file, $worksheet );
    print "   ---------------------------\n";
    $self->printer( '4i1c_l_', { label => $input_l } );
    foreach my $i ( 0..1 ) {
        $self->printer( '0i2c_rl', { label => $i_l[$i], descr => $i_v[$i] } );
    }
    return;
}

sub job_info_output_file {
    my ($self, $file, $worksheet) = @_;
    $worksheet //= 'n/a';
    my $output_l = __ 'Output:';
    my @i_l = ( __ 'file:', __ 'worksheet:' );
    my @i_v = ($file, $worksheet);
    print "   ---------------------------\n";
    $self->printer( '4i1c_l_', { label => $output_l } );
    foreach my $i ( 0..1 ) {
        $self->printer( '0i2c_rl', { label => $i_l[$i], descr => $i_v[$i] } );
    }
    return;
}

sub job_info_input_db {
    my ($self, $src_table, $src_db) = @_;
    my $input_l  = __ 'Input:';
    print "   ---------------------------\n";
    $self->printer( '4i1c_l_', { label => $input_l } );
    my @i_l = (__ 'table:', __ 'database:');
    my @i_v = ($src_table, $src_db);
    foreach my $i ( 0..1 ) {
        $self->printer( '0i2c_rl', { label => $i_l[$i], descr => $i_v[$i] } );
    }
    return;
}

sub job_info_output_db {
    my ($self, $dst_table, $dst_db) = @_;
    my $output_l = __ 'Output:';
    print "   ---------------------------\n";
    $self->printer( '4i1c_l_', { label => $output_l } );
    my @o_l = (__ 'table:', __ 'database:');
    my @o_v = ($dst_table, $dst_db);
    foreach my $i ( 0..1 ) {
        $self->printer( '0i2c_rl', { label => $o_l[$i], descr => $o_v[$i] } );
    }
    return;
}

sub job_info_prework {
    my $self = shift;
    my $start_l = __ 'Working:';
    print " -----------------------------\n";
    $self->printer( '2i1c_l_', { label => $start_l } );
    return;
}

sub job_info_postwork {
    my ($self, $rec_count) = @_;
    $rec_count //= 0;
    my $count_l = __ 'source records read:';
    $self->printer( '0i2c_rl', { label => $count_l, descr => $rec_count } );
    return;
}

sub job_summary {
    my ($self, $records_inserted, $records_skipped) = @_;
    my $summ_l = __ 'Summary:';
    print " -----------------------------\n";
    $self->printer( '2i1c_l_', , { label => $summ_l } );
    my @o_l = (__ 'records inserted:', __ 'records skipped:');
    my $ins = $records_inserted // 0;
    my $skp = $records_skipped  // 0;
    my @o_v = ($ins, $skp);
    foreach my $i ( 0..1 ) {
        $self->printer( '0i2c_rl', { label => $o_l[$i], descr => $o_v[$i] } );
    }
    print " -----------------------------\n";
    return;
}

1;

__END__

=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 OPTIONS

=head2 ATTRIBUTES

=head3 _printer

=head2 INSTANCE METHODS

=head3 job_intro

Method to print info form the recipe header.

=head3 job_info_input_file

Method to print info about the recipe input file.

=head3 job_info_output_file

Method to print info about the recipe output file.

=head3 job_info_input_db

Method to print info about the recipe input database and table.

=head3 job_info_output_db

Method to print info about the recipe output database and table.

=head3 job_info_prework

Method to print a label: Working.

=head3 job_info_postwork

Method to print the number of records read from the input.

=head3 job_summary

Method to print the summary.

=cut
