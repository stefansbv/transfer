package App::Transfer::Command::run;

# ABSTRACT: Process a recipe file

use 5.010001;
use utf8;

use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use namespace::autoclean;

extends qw(App::Transfer);

# with qw(App::Transfer::Role::Utils
#         MooseX::Log::Log4perl);

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
    isa           => File,
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

    my $io_type = $self->trafo->recipe->io_trafo_type;
    my $meth    = "transfer_$io_type";
    if ( $self->trafo->can($meth) ) {
        $self->trafo->$meth;    # execute the transfer
    }
    else {
        hurl run =>
            __x( "Wrong reader-writer combo: '{type}'!", type => $io_type );
    }
    $self->trafo->job_summary;

    return;
}

__PACKAGE__->meta->make_immutable;

1;
