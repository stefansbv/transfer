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

    hurl source =>
        __x( "The destination section must have a 'writer' attribute" )
        unless length( $p->{writer} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
