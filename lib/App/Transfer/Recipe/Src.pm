package App::Transfer::Recipe::Src;

# ABSTRACT: The data transformation recipe config section: source

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'reader' => ( is => 'ro', isa => 'Str', required => 1 );
has 'file'   => ( is => 'ro', isa => 'Str' );
has 'target' => ( is => 'ro', isa => 'Str' );
has 'table'  => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)

    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    hurl source =>
        __x( "The source section must have a 'reader' attribute" )
        unless length( $p->{reader} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
