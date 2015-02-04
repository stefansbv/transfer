package App::Transfer::Recipe::Header;

# ABSTRACT: Data transformation recipe parser

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has 'version'       => ( is => 'ro', isa => 'Natural', required => 1 );
has 'syntaxversion' => ( is => 'ro', isa => 'NaturalLessThanN', required => 1 );
has 'name'          => ( is => 'ro', isa => 'Str' );
has 'description'   => ( is => 'ro', isa => 'Str' );

sub BUILDARGS {
    my $class = shift;

    # Borrowed and adapted from Sqitch ;)
    my $p = @_ == 1 && ref $_[0] ? { %{ +shift } } : { @_ };

    hurl source =>
        __x("The recipe must have a valid 'version' attribute")
            unless length( $p->{version} // '' );
    hurl source =>
        __x("The recipe must have a valid 'syntaxversion' attribute")
            unless length( $p->{syntaxversion} // '' );

    return $p;
}

__PACKAGE__->meta->make_immutable;

1;
