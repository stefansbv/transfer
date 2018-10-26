package App::Transfer::Command::info;

# ABSTRACT: Command to print info about recipes

use 5.010001;
use utf8;
use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use Moose::Util::TypeConstraints;
use Path::Tiny qw[cwd path];
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use App::Transfer::Transform;
use namespace::autoclean;

extends qw(App::Transfer);

with qw(App::Transfer::Role::Utils);

parameter 'recipe' => (
    is            => 'ro',
    isa           => Path,
    required      => 1,
    coerce        => 1,
    documentation => q[The recipe file.],
);

###

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->recipe || hurl "Recipe file required";
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
            input_options  => {},
            output_options => {},
            recipe_file    => $self->recipe,
        );
    },
);

sub execute {
    my $self = shift;
    $self->job_info;
    return;
}

sub job_info {
    my $self = shift;

    $self->trafo->job_intro(
        name          => $self->trafo->recipe->header->name,
        version       => $self->trafo->recipe->header->version,
        syntaxversion => $self->trafo->recipe->header->syntaxversion,
        description   => $self->trafo->recipe->header->description,
    );

    my $src_type = $self->trafo->recipe->in_type;
    my $dst_type = $self->trafo->recipe->out_type;

    my $meth_src = "validate_${src_type}_src";
    my $iter;
    if ( $self->can($meth_src) ) {
        $iter = $self->$meth_src;            # read the source
    }
    else {
        hurl run =>
            __x( "\nUnimplemented reader: '{type}'!", type => $src_type );
    }

    my $meth_dst = "validate_${dst_type}_dst";
    if ( $self->can($meth_dst) ) {
        $self->$meth_dst($iter);            # write to the destination
    }
    else {
        hurl run =>
            __x( "\nUnimplemented writer: '{type}'!", type => $dst_type );
    }

    my $trafo_fields = $self->trafo->collect_recipe_fields;
    use Data::Dump; dd $trafo_fields;

    $self->job_close;

    return;
}

sub job_close {
    print " -----------------------------\n";
}

sub validate_file_src {
    my $self     = shift;
    my $src_file = $self->trafo->recipe->source->file;
    my $worksheet
        = $self->trafo->reader->can('worksheet')
        ? $self->trafo->reader->worksheet
        : undef;
    $self->trafo->job_info_input_file( $src_file, $worksheet );
    return;
}

sub validate_file_dst {
    my $self = shift;

    my $dst_file = $self->trafo->recipe->destination->file;

    # Header, sorted if the 'columns' section is available
    # if ( $self->trafo->has_no_columns_info ) {
    #     $self->trafo->writer->insert_header;
    # }
    # else {
    #     my @ordered = $self->trafo->all_ordered_fields;
    #     $self->trafo->writer->insert_header(\@ordered);
    # }

    my $worksheet
        = $self->trafo->writer->can('worksheet')
        ? $self->trafo->writer->worksheet
        : undef;

    $self->trafo->job_info_output_file($dst_file, $worksheet);

    # $self->validate_dst_file_fields;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Command to generate recipes

=head1 Description

The C<new> command.

=head1 Interface

=head2 Attributes

=head3 execute

=cut
