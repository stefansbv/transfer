package App::Transfer::Writer;

# ABSTRACT: Base class for the writer interface

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
        verbose
        debug_print
    )],
);

has [qw(reader_options writer_options)] => (
    is       => 'ro',
    isa      => 'App::Transfer::Options',
    required => 1,
);

has 'records_inserted' => (
    traits        => ['Counter'],
    is            => 'ro',
    isa           => 'Int',
    default       => 0,
    handles       => {
        inc_inserted   => 'inc',
        reset_inserted => 'reset',
    },
);

has 'records_skipped' => (
    traits        => ['Counter'],
    is            => 'ro',
    isa           => 'Int',
    default       => 0,
    handles       => {
        inc_skipped   => 'inc',
        reset_skipped => 'reset',
    },
);

sub load {
    my ( $class, $p ) = @_;

    my $transfer = $p->{transfer};

    unless ( $p->{writer} ) {
        hurl {
            ident   => 'writer',
            exitval => 1,
            message => __( "A valid writer option is required!" ),
        };
    }
    ( my $writer = delete $p->{writer} ) =~ s/-/_/g;
    my $pkg = __PACKAGE__ . "::$writer";

    # Load the writer class.
    try {
        eval "require $pkg" or die $@;
    }
    catch {
        # Emit the original error for debugging.
        $transfer->debug_print($_);

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

__END__

=encoding utf8

=head1 Name

App::Transfer::Writer - Base class for the writer interface

=head1 Synopsis

  ok my $writer = App::Transfer::Writer->load({
      transfer => $transfer,
      recipe   => $recipe,
      writer   => 'db',
      options  => $options,
  });
  $writer->insert($records);

=head1 Description

App::Transfer::Writer is the base class for all writer modules.

=head1 Interface

=head2 Constructors

=head3 C<load>

  my $writer = App::Transfer::Writer->load( \%params );

A factory method for instantiating Transfer writers. It loads the
subclass for the specified writer and calls C<new> with the hash
parameter. Supported parameters are:

=over

=item C<transfer>

The App::Transfer object.

=item C<recipe>

An L<App::Transfer::Recipe> representing the recipe in use.

=item C<writer>

The name of the writer to be used.

=item C<options>

An L<App::Transfer::Options> representing the options and configs
passed and read by the application.

=back

=head2 Attributes

=head3 C<transfer>

  my $transfer = $self->transfer;

Returns the L<App::Transfer> object that instantiated the writer.

=head3 C<recipe>

  my $recipe = $self->recipe;

Returns the L<App::Transfer::Recipe> object that instantiated the writer.

=head3 C<options>

  my $options = $self->options;

Returns the L<App::Transfer::Options> object that instantiated the writer.

=head3 C<records_inserted>

Counter for the number of the inserted records.

=head3 C<records_skipped>

Counter for the number of the skipped records.

=cut
