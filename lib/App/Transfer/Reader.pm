package App::Transfer::Reader;

# ABSTRACT: Base class for the reader interface

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use Lingua::Translit 0.23; # for "Common RON" table
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        debug
        debug_
        verbose
    )],
);

has 'options' => (
    is       => 'ro',
    isa      => 'App::Transfer::Options',
    required => 1,
);

has 'recipe' => (
    is       => 'ro',
    isa      => 'App::Transfer::Recipe',
    required => 1,
    default  => sub {
        my $self = shift;
        return $self->options->recipe;
    },
);

has 'record_count' => (
    is       => 'rw',
    isa      => 'Int',
    default => sub { return 0; },
);

has 'rows_read' => (
    is       => 'rw',
    isa      => 'Int',
    default => sub { return 0; },
);

# Transliteration
# TODO: make it configurable
has 'common_RON' => (
    is      => 'ro',
    isa     => 'Lingua::Translit',
    default => sub {
        return Lingua::Translit->new('Common RON');
    },
);

sub load {
    my ( $class, $p ) = @_;

    my $transfer = $p->{transfer};

    unless ( $p->{reader} ) {
        hurl {
            ident   => 'reader',
            exitval => 1,
            message => __( "A valid reader option is required!" ),
        };
    }
    ( my $reader = delete $p->{reader} ) =~ s/-/_/g;
    my $pkg = __PACKAGE__ . "::$reader";

    # Load the reader class.
    try {
        eval "require $pkg" or die $@;
    }
    catch {
        # Emit the original error for debugging.
        $transfer->debug_($_);

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

__END__

=encoding utf8

=head1 Name

App::Transfer::Reader - Base class for the reader interface

=head1 Synopsis

  ok my $reader = App::Transfer::Reader->load({
      transfer => $transfer,
      recipe   => $recipe,
      reader   => 'xls',
      options  => $options,
  });
  my $records = $reader->get_data;

=head1 Description

App::Transfer::Reader is the base class for all reader modules.

=head1 Interface

=head2 Constructors

=head3 C<load>

  my $reader = App::Transfer::Reader->load( \%params );

A factory method for instantiating Transfer readers.  It loads the
subclass for the specified reader and calls C<new> with the hash
parameter.  Supported parameters are:

=over

=item C<transfer>

The App::Transfer object.

=item C<recipe>

An L<App::Transfer::Recipe> representing the recipe in use.

=item C<reader>

The name of the reader to be used.

=item C<options>

An L<App::Transfer::Options> representing the options and configs
passed and read by the application.

=back

=head2 Attributes

=head3 C<transfer>

  my $transfer = $self->transfer;

Returns the L<App::Transfer> object that instantiated the reader.

=head3 C<recipe>

  my $recipe = $self->recipe;

Returns the L<App::Transfer::Recipe> object that instantiated the reader.

=head3 C<options>

  my $options = $self->options;

Returns the L<App::Transfer::Options> object that instantiated the reader.

=cut
