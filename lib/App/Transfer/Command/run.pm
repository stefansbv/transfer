package App::Transfer::Command::run;

# ABSTRACT: Command to process a recipe file

use 5.010001;
use utf8;
use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends qw(App::Transfer);

use App::Transfer::Transform;

parameter 'recipe' => (
    is            => 'ro',
    isa           => File,
    required      => 1,
    coerce        => 1,
    documentation => q[The recipe file.],
);

option 'input_file' => (
    is            => 'ro',
    isa           => File,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'in-file',
    cmd_aliases   => [qw(if)],
    documentation => q[The input file (xls | csv).],
);

option 'output_file' => (
    is            => 'ro',
    isa           => Path,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'out-file',
    cmd_aliases   => [qw(of)],
    documentation => q[The output file (xls | csv).],
);

option 'input_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-target',
    cmd_aliases   => [qw(it)],
    documentation => q[The input database target name.],
);

option 'output_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-target',
    cmd_aliases   => [qw(ot)],
    documentation => q[The output database target name.],
);

option 'input_uri' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-uri',
    cmd_aliases   => [qw(iu)],
    documentation => q[The input database URI.],
);

option 'output_uri' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-uri',
    cmd_aliases   => [qw(ou)],
    documentation => q[The output database URI.],
);

has 'input_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            input_file    => $self->input_file,
            input_target  => $self->input_target,
            input_uri     => $self->input_uri,
        };
    },
);

has 'output_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            output_file   => $self->output_file,
            output_target => $self->output_target,
            output_uri    => $self->output_uri,
        };
    },
);

has 'trafo' => (
    is      => 'ro',
    isa     => 'App::Transfer::Transform',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Transform->new(
            transfer       => $self,
            input_options  => $self->input_options,
            output_options => $self->output_options,
            recipe_file    => $self->recipe,
        );
    },
);

sub execute {
    my $self = shift;

    hurl run => __x(
        "Unknown recipe syntax version: {version}",
        version => $self->trafo->recipe->header->syntaxversion
    ) if $self->trafo->recipe->header->syntaxversion != 1; # XXX ???

    $self->trafo->job_intro;
    $self->trafo->job_transfer;
    $self->trafo->job_summary;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Command to process a recipe file

=head1 Description

The C<run> command implementation.

=head1 Interface

=head2 Attributes

The CLI options take precedence over the other configuration options.

=head3 C<recipe>

The <recipe> attribute holds the recipe file name coerced to a
Path::Tiny object.  It is a required parameter for the C<run> command.

=head3 C<input_file>

The C<input_file> attribute provides an optional input file name for
the C<run> command.  The CLI option name is C<--in-file> and the alias
is C<--if>.

=head3 C<output_file>

The C<output_file> attribute provides an optional output file name for
the C<run> command.  The CLI option name is C<--out-file> and the
alias is C<--of>.

XXX Not used yet.

=head3 C<input_target>

The C<input_file> attribute provides an optional input target name for
the C<run> command.

=head3 C<output_target>

The C<output_file> attribute provides an optional output target name
for the C<run> command.

=head3 C<input_uri>

The C<input_uri> attribute provides an optional input database URI
(URI::db) for the C<run> command.

=head3 C<output_uri>

The C<output_uri> attribute provides an optional output database URI
(URI::db) for the C<run> command.

=head3 C<input_options>

A hash reference attribute for grouping together all the input options.

=head3 C<output_options>

A hash reference attribute for grouping together all the output options.

=head3 C<trafo>

The C<trafo> attribute instantiates and holds an
L<App::Transfer::Transform> object instance.  All the action takes
place in this module.

=head2 Instance Methods

=head3 C<execute>

The C<run> command implementation.  Based on the C<reader> and
C<writer> options from the recipe, executes the apropriate method from
the L<App::Transfer::Transform> object instance.

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
