package App::Transfer::Recipe::Src;

# ABSTRACT: The data transformation recipe config section: source

use 5.010001;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'reader' => ( is => 'ro', isa => 'Str', required => 1 );
has 'file'   => ( is => 'ro', isa => File, coerce => 1 );
has 'target' => ( is => 'ro', isa => 'Str' );
has 'table'  => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    if ( $p->{reader} eq 'excel' or $p->{reader} eq 'csv' ) {
        # hurl source =>
        #     __x( "The source reader '{reader}' must have a 'file' attribute",
        #     reader => $p->{reader} )
        #     unless length( $p->{file} // '' );
    }
    elsif ( $p->{reader} eq 'db' ) {
        # hurl source =>
        #     __x( "The source reader 'db' must have a 'target' attribute" )
        #     unless length( $p->{target} // '' );
        # hurl source =>
        #     __x( "The source reader 'db' must have a 'table' attribute" )
        #     unless length( $p->{table} // '' );
    }
    else {
        hurl 'The source reader must be either "excel", "csv", or "db"';
    }

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
