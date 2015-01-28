package App::Transfer::Writer;

# ABSTRACT: Base class for the writer interface

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        comment
        emit
        debug
    )],
);

has 'records_inserted' => (
    traits        => ['Counter'],
    is            => 'ro',
    isa           => 'Int',
    default       => 0,
    handles       => { 'inc_inserted' => 'inc' },
);

has 'records_skipped' => (
    traits        => ['Counter'],
    is            => 'ro',
    isa           => 'Int',
    default       => 0,
    handles       => { 'inc_skipped' => 'inc' },
);

sub writer {
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

    # We should have a writer.
    $class->usage unless $p->{writer};
    ( my $writer = $p->{writer} ) =~ s/-/_/g;

    # Load the writer class.
    my $pkg = __PACKAGE__ . "::$writer";
    try {
        eval "require $pkg" or die $@;
    }
    catch {
        # Emit the original error for debugging.
        $transfer->debug($_);

        # Suggest help if it's not a valid writer.
        hurl {
            ident   => 'writer',
            exitval => 1,
            message => __x(
                '"{writer}" is not a valid writer', writer => $writer,
            ),
        };
    };

    # Instantiate and return the writer.
    return $pkg->new($p);
}

__PACKAGE__->meta->make_immutable;

1;
