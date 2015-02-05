package App::Transfer::Reader;

# ABSTRACT: Base class for the reader interface

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        debug
    )],
);

has 'recipe' => (
    is       => 'ro',
    isa      => 'App::Transfer::Recipe',
    required => 1,
);

has 'options' => (
    is       => 'ro',
    isa      => 'App::Transfer::Options',
    required => 1,
);

sub reader {
    my $class = ref $_[0] || shift;
    return '' if $class eq __PACKAGE__;
    my $pkg = quotemeta __PACKAGE__;
    $class =~ s/^$pkg\:://;
    $class =~ s/_/-/g;
    return $class;
}

sub load {
    my ( $class, $p ) = @_;

    my $transfer = $p->{transfer};

    # We should have a reader.
    $class->usage unless $p->{reader};
    ( my $reader = delete $p->{reader} ) =~ s/-/_/g;

    # Load the reader class.
    my $pkg = __PACKAGE__ . "::$reader";
    try {
        eval "require $pkg" or die $@;
    }
    catch {
        # Emit the original error for debugging.
        $transfer->debug($_);

        # Suggest help if it's not a valid reader.
        hurl {
            ident   => 'reader',
            exitval => 1,
            message => __x(
                '"{reader}" is not a valid reader', reader => $reader,
            ),
        };
    };

    # Instantiate and return the reader.
    return $pkg->new($p);
}

__PACKAGE__->meta->make_immutable;

1;
