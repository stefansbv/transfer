package App::Transfer::Command::config;

# ABSTRACT: Configure the application

use 5.010001;
use utf8;
use MooseX::App::Command;
use Moose::Util::TypeConstraints;
use Try::Tiny;
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends qw(App::Transfer);

parameter 'action' => (
    is            => 'rw',
    isa           => enum( [qw(set dump rm)] ),
    required      => 1,
    documentation => q[Subcommands],
);

option 'context_local' => (
    is            => 'ro',
    isa           => 'Bool',
    required      => 0,
    cmd_flag      => 'local',
    documentation => q[Select the local context.],
);

option 'context_user' => (
    is            => 'ro',
    isa           => 'Bool',
    required      => 0,
    cmd_flag      => 'user',
    documentation => q[Select the user context.],
);

option 'context_system' => (
    is            => 'ro',
    isa           => 'Bool',
    required      => 0,
    cmd_flag      => 'system',
    documentation => q[Select the system context.],
);

option 'target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'target',
    documentation => q[The target name.],
);

option 'uri_str' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'uri',
    documentation => q[The database URI string.],
);

has context => (
    is  => 'rw',
    isa => enum( [qw(
        local
        user
        system
    )] ),
);

has 'file' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $meth = $self->context . '_file';
        return $self->config->$meth;
    }
);

sub execute {
    my ( $self ) = @_;

    # Set
    if ( $self->action eq 'set' ) {
        $self->set_context;
        hurl "Required arguments missing: target name and database URI."
            unless $self->target and $self->uri_str;
        $self->set_target($self->target, $self->uri_str);
    }

    # Dump
    if ( $self->action eq 'dump' ) {
        my %conf = $self->config->dump;
        say "Current config:";
        say " none!" if scalar keys %conf == 0;
        while ( my ( $key, $value ) = each %conf ) {
            print " $key = $value\n";
        }
    }

    # Remove
    if ( $self->action eq 'rm' ) {
        $self->set_context;
        hurl "Required arguments missing: target name."
            unless $self->target;
        $self->remove_target($self->target);
    }

    return;
}

sub set_context {
    my $self = shift;
    hurl config => "Context must be ONE of 'local', 'user' or 'system'."
        unless ( $self->context_local xor $self->context_user
        xor $self->context_system );
    hurl config =>
        "Context must be ONE of 'local', 'user' or 'system', not all."
        if ($self->context_local
        and $self->context_user
        and $self->context_system );
    my $context;
    $context = 'local'  if $self->context_local;
    $context = 'user'   if $self->context_user;
    $context = 'system' if $self->context_system;
    $self->context($context);
    return;
}

sub set_target {
    my ($self, $name, $uri) = @_;
    hurl "Required arguments missing: 'name' and 'uri'"
        unless $name and $uri;
    $self->_set("target.${name}.uri", $uri);
    return;
}

sub remove_target {
    my ($self, $name) = @_;
    hurl "Required arguments missing: 'name'"
        unless $name;
    $self->remove_section("target.${name}");
    return;
}

sub _set {
    my ( $self, $key, $value ) = @_;

    hurl "Wrong number of arguments."
        if !defined $key || $key eq '' || !defined $value;

    print "Config write to ", $self->file, "...\r";

    $self->_touch_dir;
    try {
        $self->config->set(
            key      => $key,
            value    => $value,
            filename => $self->file,
        );
    }
    catch {
        say "Config write to ", $self->file, "...failed";
        say "[EE] Config: $_";
    };

    say "Config write to ", $self->file, "...done";

    return $self;
}

sub remove_section {
    my ( $self, $section ) = @_;

    hurl "Wrong number of arguments."
        unless defined $section && $section ne '';

    try {
        $self->config->remove_section(
            section  => $section,
            filename => $self->file,
        );
    }
    catch {
        hurl config => __ 'No such section!' if /\Qno such section/i;
        hurl config => $_;
    };
    return $self;
}

sub _touch_dir {
    my $self = shift;
    unless ( -e $self->file ) {
        require File::Basename;
        my $dir = File::Basename::dirname( $self->file );
        unless ( -e $dir && -d _ ) {
            require File::Path;
            File::Path::make_path($dir);
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Command to create, dump or remove configurations

=head1 Description

The C<config> command.

=head1 Interface

=head2 Attributes

=head3 C<action>

The <action> attribute holds the subcommand to be run.  It is a
required parameter for the C<config> command.

=head3 C<context_local>

The C<context_local> attribute holds the value of the CLI option
C<--local>.  It is used to select the local context.

=head3 C<context_user>

The C<context_user> attribute holds the value of the CLI option
C<--user>.  It is used to select the user context.

=head3 C<context_system>

The C<context_system> attribute holds the value of the CLI option
C<--system>.  It is used to select the system context.

=head3 C<target>

Option for the target name.

=head3 C<uri_str>

Option for the URI string.

=head3 C<context>

The configuration file context.  Must be one of:

=over

=item * C<local>

=item * C<user>

=item * C<system>

=back

=head3 C<file>

  my $file_name = $config->file;

Returns the path to the configuration file to be acted upon.  If the
context is C<system>, then the value returned is
C<$($etc_prefix)/transfer.conf>.  If the context is C<user>, then the
value returned is C<~/.transfer/transfer.conf>.  Otherwise, the default is
F<./transfer.conf>.

=head2 Instance Methods

=head3 C<execute>

Call the method mapped to the subcommand.

=head3 C<set_context>

Set the context from the options passed on the CLI.

=head3 C<set_target>

Write the target configuration to the file.

=head3 C<remove_target>

Remove the target from configuration file.

=head3 C<_set>

Set a key and a configuration value.

=head3 C<remove_section>

Remove a section from the configuration.

=head3 C<_touch_dir>

Make the configuration path if necessary.

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
