package App::Transfer::Target;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use Path::Class qw(dir file);
use Params::Coerce ();
use URI::db;
use namespace::autoclean;

subtype 'URIdb' => as 'URI::db';
coerce  'URIdb' => from 'Str' => via { URI::db->new( $_ ) };

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 0,
    default  => sub { 'anonim' },
);

sub target { shift->name }

has uri => (
    is       => 'ro',
    isa      => 'URIdb',
    required => 1,
    coerce   => 1,
    handles  => {
        engine_key => 'canonical_engine',
        dsn        => 'dbi_dsn',
        username   => 'user',
        password   => 'password',
    },
);

has engine => (
    is      => 'ro',
    isa     => 'App::Transfer::Engine',
    lazy    => 1,
    default => sub {
        my $self   = shift;
        require App::Transfer::Engine;
        App::Transfer::Engine->load({
            transfer => $self->transfer,
            target   => $self,
        });
    },
);

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Target - Transfer reader or writer database target

=head1 Synopsis

  my $target = App::Transfer::Target->new(
      transfer => $transfer,
      uri      => 'db:...',
  );


=head1 Description

App::Transfer::Target provides the L<engine|App::Transfer::Engine>
required to carry out Transfer commands. All commands should
instantiate a target to work with a database.

=head1 Interface

=head3 C<new>

  my $target = App::Transfer::Target->new( transfer => $transfer );

Instantiates and returns an App::Transfer::Target object. The most important
parameters are C<transfer>, C<name> and C<uri>.

TODO: Adapt for Transfer:

As a general rule, then, pass either a target name or URI string in the
C<name> parameter, and Transfer will do its best to find all the relevant target
information. And if there is no name or URI, it will try to construct a
reasonable default from the command-line options or engine configuration.

=head2 Accessors

=head3 C<transfer>

  my $transfer = $target->transfer;

Returns the L<App::Transfer> object that instantiated the target.

=head3 C<name>

=head3 C<target>

  my $name = $target->name;
  $name = $target->target;

The name of the target. If there was no name specified, the URI will be used
(minus the password, if there is one).

=head3 C<uri>

  my $uri = $target->uri;

The L<URI::db> object encapsulating the database connection information.

=head3 C<engine>

  my $engine = $target->engine;

A L<App::Transfer::Engine> object to use for database interactions with the
target.

=head3 C<engine_key>

  my $key = $target->engine_key;

The key defining which engine to use. This value defines the class loaded by
C<engine>. Convenience method for C<< $target->uri->canonical_engine >>.

=head3 C<dsn>

  my $dsn = $target->dsn;

The DSN to use when connecting to the target via the DBI. Convenience method
for C<< $target->uri->dbi_dsn >>.

=head3 C<username>

  my $username = $target->username;

The username to use when connecting to the target via the DBI. Convenience
method for C<< $target->uri->user >>.

=head3 C<password>

  my $password = $target->password;

The password to use when connecting to the target via the DBI. Convenience
method for C<< $target->uri->password >>.

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

Copyright (c) 2014-2015 Ștefan Suciu.

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
