package App::Transfer::Recipe::Dst;

# ABSTRACT: The data transformation recipe config section: destination

use 5.010001;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'writer' => ( is => 'ro', isa => 'Str', required => 1 );
has 'file'   => ( is => 'ro', isa =>  File, coerce => 1 );
has 'target' => ( is => 'ro', isa => 'Str' );
has 'table'  => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    if ( $p->{writer} eq 'excel' or $p->{writer} eq 'csv' ) {
        # hurl destination =>
        #     __x( "The destination writer '{writer}' must have a 'file' attribute",
        #     writer => $p->{writer} )
        #     unless length( $p->{file} // '' );
    }
    elsif ( $p->{writer} eq 'db' ) {
        # hurl destination =>
        #     __x( "The destination writer 'db' must have a 'target' attribute" )
        #     unless length( $p->{target} // '' );
        # hurl destination =>
        #     __x( "The destination writer 'db' must have a 'table' attribute" )
        #     unless length( $p->{table} // '' );
    }
    else {
        hurl 'The destination writer must be either "excel", "csv", or "db"';
    }

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
