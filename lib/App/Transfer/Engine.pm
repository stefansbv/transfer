package App::Transfer::Engine;

# ABSTRACT: Transfer database engine base class

use 5.010001;
use Moose;
use URI::db;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        debug
        verbose
    )],
);

has target => (
    is       => 'ro',
    isa      => 'App::Transfer::Target',
    required => 1,
    weak_ref => 1,
    handles => {
        uri         => 'uri',
        destination => 'name',
    }
);

sub database { shift->destination }

sub load {
    my ( $class, $p ) = @_;

    # We should have an target param.
    my $target = $p->{target} or hurl 'Missing "target" parameter to load()';

    # Load the engine class.
    my $ekey = $target->engine_key or hurl engine => __(
        'No engine specified; use --engine or set core.engine'
    );

    my $pkg = __PACKAGE__ . '::' . $target->engine_key;
    eval "require $pkg" or hurl "Unable to load $pkg";
    return $pkg->new( $p );
}

sub driver { shift->key }

sub key {
    my $class = ref $_[0] || shift;
    hurl engine => __ 'No engine specified; use --engine or set core.engine'
        if $class eq __PACKAGE__;
    my $pkg = quotemeta __PACKAGE__;
    $class =~ s/^$pkg\:://;
    return $class;
}

sub name { shift->key }

sub use_driver {
    my $self = shift;
    my $driver = $self->driver;
    eval "use $driver";
    hurl $self->key => __x(
        '{driver} required to manage {engine}',
        driver  => $driver,
        engine  => $self->name,
    ) if $@;
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Engine -  Transfer database engine base class

=head1 Synopsis

  my $engine = App::Transfer::Engine->new( transfer => $transfer );

=head1 Description

App::Transfer::Engine provides the base class for all Transfer
database engines.  Most likely this will not be of much interest to
you unless you are hacking on the engine code.

=head1 Interface

=head2 Class Methods

=head3 C<key>

  my $name = App::Transfer::Engine->key;

The key name of the engine. Should be the last part of the package name.

=head3 C<name>

  my $name = App::Transfer::Engine->name;

The name of the engine. Returns the same value as C<key> by default, but
should probably be overridden to return a display name for the engine.

=head3 C<driver>

  my $driver = App::Transfer::Engine->driver;

The name and version of the database driver to use with the engine, returned
as a string suitable for passing to C<use>. Used internally by C<use_driver()>
to C<use> the driver and, if it dies, to display an appropriate error message.
Must be overridden by subclasses.

=head3 C<use_driver>

  App::Transfer::Engine->use_driver;

Uses the driver and version returned by C<driver>. Returns an error on failure
and returns true on success.

=head2 Constructors

=head3 C<load>

  my $cmd = App::Transfer::Engine->load(%params);

A factory method for instantiating Transfer engines. It loads the subclass for
the specified engine and calls C<new>, passing the Transfer object. Supported
parameters are:

=over

=item C<transfer>

The App::Transfer object driving the whole thing.

=back

=head3 C<new>

  my $engine = App::Transfer::Engine->new(%params);

Instantiates and returns a App::Transfer::Engine object.

=head2 Instance Accessors

=head3 C<transfer>

The current Transfer object.

=head3 C<target>

A string identifying the database target.

Returns the name of the target database. This will usually be the name of
target specified on the command-line, or the default.

=head3 C<uri>

A L<URI::db> object representing the target database. Defaults to a URI
constructed from the L<App::Transfer> C<db_*> attributes.

=head3 C<database>

A string identifying the target database.

=head2 Instance Methods

=head1 See Also

=over

=item L<transfer>

The Transfer command-line client.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
