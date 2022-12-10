package App::Transfer::Options;

# ABSTRACT: Reader or writer options builder

use 5.010001;
use Moose;
use Path::Tiny;
use MooseX::Types::Path::Tiny qw(File Path);
use Locale::TextDomain 1.20 qw(App-Transfer);
use Scalar::Util qw(blessed);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        warn
    )],
);

has '_options' => (
    is       => 'ro',
    isa      => 'Maybe[HashRef]',
    init_arg => 'options',
    default  => sub { {} },
);

has 'rw_type' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'config' => (
    is      => 'ro',
    isa     => 'App::Transfer::Config',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->transfer->config;
    },
);

has 'recipe' => (
    is  => 'ro',
    isa => 'App::Transfer::Recipe',
);

has 'target' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {''},
);

has uri_str => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_db_options',
);

has 'file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    coerce  => 1,
    builder => '_build_file_options',
);

sub _build_file_options {
    my $self     = shift;
    my $rw_type  = $self->rw_type;
    my $required = 0;
    my ( $option, $section );
    if ( $rw_type eq 'reader' ) {
        $option = 'input_file';
        $section  = 'source';
        $required = 1;
    }
    elsif ( $rw_type eq 'writer' ) {
        $option  = 'output_file';
        $section = 'destination';
    }
    else {
        hurl options => __x("Unknown reader/writer type");
    }

    # 1. Command line options
    my $opts = $self->_options;

    if ( keys %{$opts} ) {

        # 1.1 We have a FILE
        if ( $section eq 'destination' ) {
            if ( my $file = $opts->{$option} ) {
                my $file = path $file;
                if ( my $dir = $file->parent ) {
                    hurl {
                        ident   => 'options:invalid',
                        message => __x(
                            "The parent dir '{dir}' was not found!",
                            dir => $dir
                        ),
                    } if !$dir->is_dir;
                }
                return $file;
            }
        }
        else {
            if ( my $file = $opts->{$option} ) {
                $file = path $file;
                if ($required) {
                    hurl {
                        ident   => 'options:invalid',
                        message => __x(
                            "The file '{file}' was not found!",
                            file => $file
                        ),
                    } if !$file->is_file;
                }
                return $file;
            }
        }
    }

    # 2. Recipe config section
    if ( my $recipe = $self->recipe ) {
        if ( $section eq 'destination' ) {
            if ( my $file = $recipe->$section->file ) {
                my $file = path $file;
                if ( my $dir = $file->parent ) {
                    hurl {
                        ident   => 'options:invalid',
                        message => __x(
                            "The parent dir '{dir}' was not found!",
                            dir => $dir
                        ),
                    } if !$dir->is_dir;
                }
                return $file;
            }
        }
        else {
            if ( my $file = $recipe->$section->file ) {
                $file = path $file;
                hurl {
                    ident   => 'options:invalid',
                    message => __x(
                        "The file '{file}' was not found!",
                        file => $file
                    ),
                } if !$file->is_file;
                return $file;
            }
        }
    }

    # 3. Configuration files
    # NO, not yet

    hurl {
        ident   => 'options:missing',
        message => __x(
            "The file {rw_type} must have a valid file option or configuration.",
            rw_type => $rw_type
        ),
    };
    return;
}

has 'path' => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_path_options',
);

sub _build_path_options {
    my $self     = shift;
    my $rw_type  = $self->rw_type;
    my $required = 0;
    my ( $option, $section );
    if ( $rw_type eq 'reader' ) {
        hurl options => __("Path option not available for the reader");
        return;
    }
    elsif ( $rw_type eq 'writer' ) {
        $option  = 'output_path';
        $section = 'destination';
    }
    else {
        hurl options => __("Unknown reader/writer type");
    }

    # 1. Command line options
    my $opts = $self->_options;

    if ( keys %{$opts} ) {

        # 1.1 We have a PATH
        if ( my $path = $opts->{$option} ) {
            $path = path $path;
            hurl {
                ident   => 'options:invalid',
                message => __x(
                    "The dir '{dir}' was not found!",
                    dir => $path
                ),
            } if !$path->is_dir;
            return $path;
        }
    }

    # 2. Recipe config section
    if ( my $recipe = $self->recipe ) {
        if ( $section eq 'destination' ) {
            if ( my $path = $recipe->$section->path ) {
                $path = path $path;
                hurl {
                    ident   => 'options:invalid',
                    message => __x(
                        "The dir '{dir}' was not found!",
                        dir => $path
                    ),
                } if !$path->is_dir;
                return $path;
            }
        }
        else {
            hurl options => "Something went very wrong!";
        }
    }

    return '.';
}

sub _build_db_options {
    my $self = shift;

    my ($uri, $name);                       # URI, target name
    my $rw_type = $self->rw_type;
    my ( $opt_uri, $opt_target, $section );
    if ( $rw_type eq 'reader' ) {
        $opt_uri    = 'input_uri';
        $opt_target = 'input_target';
        $section    = 'source';
    }
    elsif ( $rw_type eq 'writer' ) {
        $opt_uri    = 'output_uri';
        $opt_target = 'output_target';
        $section    = 'destination';
    }
    else {
        hurl options => __x("Unknown reader/writer type");
    }

    # 1. Command line options
    my $opts = $self->_options;
    if ( keys %{$opts} ) {

        # 1.1 We have an URI
        if ( $uri = $opts->{$opt_uri} ) {

            # The name is the default
            $self->warn(
                __x( 'The URI option supersede the target option', ) )
                if $opts->{$opt_target};
            return blessed($uri) ? $uri->as_string : $uri;
        }
        elsif ( $name = $opts->{$opt_target} ) {

            # 1.2 We have a target name, get the URI
            if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
                $self->target($name);
                return blessed($uri) ? $uri->as_string : $uri;
            }
        }
    }

    # 2. Recipe config section
    if ($name) {

        # We already have a name from CLI
        $self->target($name);
        if ( $uri = $self->recipe->get_uri($name) ) {
            return blessed($uri) ? $uri->as_string : $uri;
        }
    }
    else {
        # 2.1 Target name from recipe
        if ( $name = $self->recipe->$section->target ) {
            $self->target($name);
            if ( $uri = $self->recipe->get_uri($name) ) {
                return blessed($uri) ? $uri->as_string : $uri;
            }
        }
    }

    # 3. Configuration files
    if ($name) {

        # We already have a target name from CLI or recipe
        $self->target($name);
        if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
            return blessed($uri) ? $uri->as_string : $uri;
        }
    }
    else {
        if ( $name = $self->config->get( key => "$section.target" ) ) {
            $self->target($name);
            if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
                return blessed($uri) ? $uri->as_string : $uri;
            }
        }
    }

    hurl {
        ident => 'options:missing',
        message => __x(
            "The db {rw_type} must have a valid target or URI option or configuration.",
            rw_type => $rw_type
        ),
    } if !$uri;
    return;
}

sub _get_uri_from_config {
    my ($self, $name) = @_;
    my $config = $self->transfer->config;
    return $config->get( key => 'target.' . $name . '.uri' );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Options - Options builder for reader or writer

=head1 Synopsis

  my $options = App::Transfer::Options->new(
      transfer => $transfer,
      options  => $cli_options,
      rw_type  => 'reader',
  );

=head1 Description

App::Transfer::Options builds the attributes from the command line
options provided by the user, the configurations found in the recipes
and the application configuration files, in this order.

=head1 Interface

=head3 C<new>

Instantiates and returns an App::Transfer::Options object.

  my $options = App::Transfer::Options->new(
      transfer => $transfer,
      options  => $cli_options,
      rw_type  => 'reader',
  );

The parameters:

=over

=item C<transfer>

The App::Transfer object.

=item C<options>

A hash reference with the CLI options passed to the application.

=item C<rw_type>

The option type to build.  Can be L<reader> or L<writer>.

=back

All parameters are required.

=head2 Accessors

=head3 C<transfer>

  my $transfer = $self->transfer;

Returns the L<App::Transfer> object that instantiated the options.

=head3 C<options>

Returns the options hash reference.

=head3 C<rw_type>

Returns 'reader' or 'writer'.

=head3 C<config>

The L<App::Transfer::Config> object.

=head3 C<recipe>

  my $recipe = $self->recipe;

Returns the L<App::Transfer::Recipe> object that instantiated the options.

=head3 C<target>

A string representing the target name passed to the options, if any.
Defaults to ''.

=head3 C<uri_str>

Builds and returns the URI string for the DB reader or writer.  The
CLI options take precedence over the other configuration sources.

=over

=item *

If we have a C<--input-uri> for a reader option or a C<--output-uri>
for a writer option, than return it.

Warn if we also have target options.

=item *

If we have a C<--input-target> or a C<--output-target> option, than
return the corresponding URI string from the application
configuration, or from the recipe configuration section, if any.

=item *

If we have a target name defined in the recipe configuration section,
return the coresponding URI string from the recipe.

=item *

If we have a target name from above, return the URI string from the
application configuration, if any.

=item *

If no target name so far, search in the application configuration, for
the target name and return the coresponding URI string.

=item *

Finaly, throw an error if we got this far without finding a valid URI
string.

=back

=head3 C<file>

Builds and returns a C<Path::Class> object from a file path for the
file reader or writer.  The CLI options take precedence over the other
configuration sources.

=over

=item *

If we have a C<--input-file> for a reader option or a C<--output-file>
for a writer option, than return a C<Path::Class> object from it.

=item *

If we have a file name defined in the recipe C<config> C<source>
subsection for a reader option or in the C<destination> subsection for
a writer option, return a C<Path::Class> object for it.

=item *

Finaly, throw an error if we got this far without finding a valid file
path.

=back

=head2 Instance Methods

=head3 C<_get_uri_from_config>

Returns the URI with a L<$name> target name from the application
configs.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

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
