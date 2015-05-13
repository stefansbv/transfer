package App::Transfer::Command::new;

# ABSTRACT: Command to generate recipes

use 5.010001;
use utf8;
use MooseX::App::Command;
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

option 'input_table' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'in-table',
    cmd_aliases   => [qw(itb)],
    documentation => q[The input table name.],
);

option 'output_table' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'out-table',
    cmd_aliases   => [qw(otb)],
    documentation => q[The output table name.],
);

option 'input_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'in-target',
    cmd_aliases   => [qw(itg)],
    documentation => q[The input database target name.],
);

option 'output_target' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'out-target',
    cmd_aliases   => [qw(otg)],
    documentation => q[The output database target name.],
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

sub execute {
    my ( $self ) = @_;

    $self->generate_recipe;

    return;
}

sub generate_recipe {
    my ($self, $opts) = @_;

    print "Generating recipe...\r";

    my ($user_name, $user_email) = $self->get_gitconfig;

    my $recipe_fn   = "recipe-table.conf";
    my $output_path = cwd;

    if ( -f path($output_path, $recipe_fn) ) {
        print "Creating recipe...skipped\n";
        return;
    }

    # use Data::Dump; dd $args;

    my $src_engine = $self->src_target->engine;
    my $dst_engine = $self->dst_target->engine;

    my $src_table = $self->input_table;
    my $dst_table = $self->output_table;

    my $src_table_info = $src_engine->get_columns($src_table);
    my $dst_table_info = $dst_engine->get_columns($dst_table);

    my $lc = List::Compare->new('--unsorted', $src_table_info, $dst_table_info);
    my @l_fields = $lc->get_Lonly;           # TODO: compare in/out fields
    my @r_fields = $lc->get_Ronly;
    my @columns  = $lc->get_union;

    my $data = {
        copy_author => $user_name,
        copy_email  => $user_email,
        copy_year   => (localtime)[5] + 1900,
        columns     => \@columns,
        reader      => 'db',
        writer      => 'db',
        src_target  => $self->input_target,
        dst_target  => $self->output_target,
        src_table   => $src_table,
        dst_table   => $dst_table,
        order_field => 'field',
    };

    my $args = {
        type        => 'recipe',
        output_file => $recipe_fn,
        data        => { r => $data },
        output_path => $output_path,
        templ_path  => undef,
    };

    App::Transfer::Render->new->render($args);

    print "Generating recipe...done\n";

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

=head2 Instance Methods

=head3 C<execute>

Call the method mapped to the subcommand.

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
