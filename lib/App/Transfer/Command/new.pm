package App::Transfer::Command::new;

# ABSTRACT: Command to generate recipes

use 5.010001;
use utf8;
use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw(Path File);
use Moose::Util::TypeConstraints;
use Path::Tiny qw[cwd path];
use File::HomeDir;
use List::Compare;
use Config::GitLike;
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use App::Transfer::Target;
use App::Transfer::Render;
use namespace::autoclean;

extends qw(App::Transfer);

with qw(App::Transfer::Role::Utils);

parameter 'recipe' => (
    is            => 'ro',
    isa           => Path,
    required      => 0,
    coerce        => 1,
    documentation => q[The new recipe file. Defaults to recipe-<table>.],
);

option 'input_table' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-table',
    cmd_aliases   => [qw(itb)],
    documentation => q[The input table name.],
    # depends       => [qw(input_target)],
);

option 'output_table' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-table',
    cmd_aliases   => [qw(otb)],
    documentation => q[The output table name.],
    #depends       => [qw(output_target)],
);

option 'input_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'in-target',
    cmd_aliases   => [qw(itg)],
    documentation => q[The input database target name.],
    mutexgroup    => 'InputFileORDb',
);

option 'output_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'out-target',
    cmd_aliases   => [qw(otg)],
    documentation => q[The output database target name.],
    mutexgroup    => 'OutputFileORDb',
);

option 'input_file' => (
    is            => 'ro',
    isa           => Path,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'in-file',
    cmd_aliases   => [qw(if)],
    documentation => q[The input file (xls|csv|dbf|odt).],
);

option 'output_file' => (
    is            => 'ro',
    isa           => Path,
    required      => 0,
    coerce        => 1,
    cmd_flag      => 'out-file',
    cmd_aliases   => [qw(of)],
    documentation => q[The output file (csv|dbf).],
);

option 'in_file_format' => (
    is            => 'ro',
    isa           => enum( [qw(xls csv dbf odt)] ),
    required      => 0,
    cmd_flag      => 'in-file-format',
    cmd_aliases   => [qw(iff)],
    documentation => q[The input file format.],
    mutexgroup    => 'InputFileORDb',
);

option 'out_file_format' => (
    is            => 'ro',
    isa           => enum( [qw(csv dbf)] ),
    required      => 0,
    cmd_flag      => 'out-file-format',
    cmd_aliases   => [qw(off)],
    documentation => q[The output file format.],
    mutexgroup    => 'OutputFileORDb',
);

###

has 'recipe_fn' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $table = $self->output_table || $self->input_table || 'unknown';
        my $recipe_fn
            = $self->recipe
            ? $self->recipe->stringify
            : "recipe-${table}.conf";
        return path $recipe_fn;
    },
);

has 'src_target' => (
    is      => 'ro',
    isa     => 'App::Transfer::Target',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Target->new(
            transfer => $self,
            uri      => $self->src_uri_str,
        );
    },
);

has src_uri_str => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_src_uri',
);

sub _build_src_uri {
    my $self = shift;
    my $name = $self->input_target;
    return $self->_get_uri_from_config($name);
}

has 'dst_target' => (
    is      => 'ro',
    isa     => 'App::Transfer::Target',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Target->new(
            transfer => $self,
            uri      => $self->dst_uri_str,
        );
    },
);

has dst_uri_str => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_dst_uri',
);

sub _build_dst_uri {
    my $self = shift;
    my $name = $self->output_target;
    return $self->_get_uri_from_config($name);
}

has 'in_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $type;
        $type = 'file' if $self->in_file_format;
        $type = 'db'   if $self->input_target;
        return $type;
    },
);

has 'reader_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 'db' if $self->input_target;
        return $self->in_file_format if $self->in_file_format;
        return;
    },
);

has 'out_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $type;
        $type = 'file' if $self->out_file_format;
        $type = 'db'   if $self->output_target;
        return $type;
    },
);

has 'writer_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 'db' if $self->output_target;
        return $self->out_file_format if $self->out_file_format;
        return;
    },
);

sub execute {
    my ( $self ) = @_;

    $self->generate_recipe;

    return;
}

sub src_table_info {
    my $self = shift;
    my $info = [];
    my $in_type = $self->in_type;
    if ( $in_type eq 'file' ) {
        $info = $self->input_file_info;
    }
    elsif ( $in_type eq 'db' ) {
        $info = $self->input_db_info;
    }
    else {
        die "Wrong input type: '$in_type'!";
    }
    return $info;
}

sub dst_table_info {
    my $self = shift;
    my $info = [];
    my $out_type = $self->out_type;
    if ( $out_type eq 'file' ) {
        $info = $self->output_file_info;
    }
    elsif ( $out_type eq 'db' ) {
        $info = $self->output_db_info;
    }
    else {
        die "Wrong output type: '$out_type'!";
    }
    return $info;
}

sub input_file_info {
    my $self = shift;
    # TODO
    return [];
}

sub input_db_info {
    my $self = shift;
    my $src_engine = $self->src_target->engine;
    my $src_table  = $self->input_table;
    my $src_table_info = $src_engine->get_columns($src_table);
    return $src_table_info;
}

sub output_file_info {
    my $self = shift;
    # TODO
    return [];
}

sub output_db_info {
    my $self = shift;
    my $dst_engine = $self->dst_target->engine;
    my $dst_table = $self->output_table;
    my $dst_table_info = $dst_engine->get_columns($dst_table);
    return $dst_table_info;
}

sub table_fields {
    my ( $self, $src_table_info, $dst_table_info ) = @_;
    die "Table info is required for 'table_fields'!"
        unless $src_table_info and $dst_table_info;
    my $lc = List::Compare->new( '--unsorted', $src_table_info,
        $dst_table_info );
    my @l_fields = $lc->get_Lonly;           # TODO: compare in/out fields
    my @r_fields = $lc->get_Ronly;
    my @columns  = $lc->get_intersection;
    if (@columns <= 0) {
        say "No common fields between the input and output tables.";
        say " Input fields:";
        say " ", join ', ', @l_fields;
        say " ---";
        say " Output fields:";
        say " ", join ', ', @r_fields;
    }
    return \@columns;
}

sub generate_recipe {
    my ($self, $opts) = @_;

    print "\nGenerating recipe...\r";

    my ($user_name, $user_email) = $self->get_gitconfig;

    my $table       = $self->input_table;
    my $recipe_fn   = $self->recipe_fn;
    my $output_path = cwd;
    if ( -f path($output_path, $recipe_fn) ) {
        print "Generating recipe... skipped\n";
        return;
    }

    my $columns = $self->table_fields(
        $self->src_table_info, $self->dst_table_info);
    my $src_file = $self->input_file
        ? $self->input_file->stringify
        : undef;
    my $dst_file = $self->output_file
        ? $self->output_file->stringify
        : undef;

    my $data = {
        copy_author => $user_name,
        copy_email  => $user_email,
        copy_year   => (localtime)[5] + 1900,
        columns     => $columns,
        reader      => $self->reader_type,
        writer      => $self->writer_type,
        src_target  => $self->input_target,
        dst_target  => $self->output_target,
        src_table   => $self->input_table,
        dst_table   => $self->output_table,
        src_file    => $src_file,
        dst_file    => $dst_file,
        order_field => 'field',
    };

    my $args = {
        type        => 'recipe',
        output_file => $recipe_fn->stringify,
        recipe_data => { r => $data },
        output_path => $output_path,
        templ_path  => $self->config->templ_path,
    };

    App::Transfer::Render->new($args)->render;

    print "Generating recipe... done\n";

    return;
}

sub _get_uri_from_config {
    my ($self, $name) = @_;
    my $config = $self->config;
    if ( my $uri = $config->get( key => 'target.' . $name . '.uri' ) ) {
        return $uri;
    }
    else {
        hurl "Can't get the URI for target '$name'!";
    }
}

sub get_gitconfig {
    my $self = shift;

    my $config_file = path( File::HomeDir->my_home, '.gitconfig');

    unless ( $config_file->is_file ) {
        print "A git configuration file was not found!\n";
        print "# Usage:\n";
        print "# git config --global user.name 'John Doe'\n";
        print "# git config --global user.email johndoe\@example.com\n";
        return ('<user name here>', '<user e-mail here>');
    }

    my $c = Config::GitLike->new( confname => $config_file->stringify );
    my $user  = $c->get( key => 'user.name' );
    my $email = $c->get( key => 'user.email' );

    return ($user, $email);
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

=head3 recipe_fn

=head3 src_target

=head3 src_uri_str

=head3 dst_target

=head3 dst_uri_str

=head3 in_type

=head3 reader_type

=head3 out_type

=head3 writer_type

=head2 Instance Methods

=head3 _build_src_uri

=head3 _build_dst_uri

=head3 execute

Call the method mapped to the subcommand.

=head3 src_table_info

=head3 dst_table_info

=head3 input_file_info

Return meta-data regarding the input table fields.

=head3 input_db_info

Return meta-data regarding the input table fields.

=head3 output_db_info

Return meta-data regarding the output table fields.

=head3 output_file_info

Return meta-data regarding the output table fields.

=head3 table_fields

=head3 generate_recipe

Generate a recipe file, filled with the basic data.

=head3 _get_uri_from_config

=head3 get_gitconfig

Get the author name and email from the git configuration file.

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
