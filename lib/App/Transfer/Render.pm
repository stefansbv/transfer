package App::Transfer::Render;

# ABSTRACT: Render a file from a template

use 5.010001;
use utf8;
use Moose;
use Template;
use Path::Tiny;
use Try::Tiny;
use MooseX::Types::Path::Tiny qw(File Path);
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use namespace::autoclean;

has 'type' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return 'recipe';
    },
);

has 'recipe_data' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'output_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'output_path' => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    default => sub {
        return path '.';
    },
);

has 'templ_path' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
);

sub render {
    my $self = shift;
    my $type        = $self->type;
    my $output_file = $self->output_file;

    my $template = try { $self->get_template }
    catch {
        hurl {
            ident => 'render',
                exitval => 1,
                message => __x( 'Template error: {error}', error => $_ ),
            };
    };

    my $tt = Template->new(
        INCLUDE_PATH => $self->templ_path->stringify,
        OUTPUT_PATH  => $self->output_path->stringify,
    );

    $tt->process( $template, $self->recipe_data, $output_file, binmode => ':utf8' )
        || hurl {
            ident => 'render',
                exitval => 1,
                message => __x( 'Template error: {error}', error => $tt->error() ),
            };

    return path($self->output_path, $output_file);
}

sub get_template {
    my $self = shift;
    my $type = $self->type;
    my $template =
         $type eq q{}      ? $self->template_type_error
       : $type eq 'recipe' ? 'recipe.tt'
       :                     $self->template_type_error;
    return $template;
}

sub template_type_error {
    my $self = shift;
    my $type = $self->type;
    hurl {
        ident => 'render',
            exitval => 1,
            message => __x "Template error, unknown type: '{type}'", type => $type,
        };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS

    my $args = {
        data        => { r => $data },
        output_file => 'test-render-recipe.conf',
    };
    my $atr  = App::Transfer::Render->new($args);
    my $file = $atr->render;

=head1 DESCRIPTION

Generate a file from templates.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 type

Optional type attribute.  The default value is I<recipe> and is the
only one recognized. :)

=head3 data

The data argument passed to the module has to be a hash reference with
the key <r>;

    data => { r => $data },

=head3 output_file

=head3 output_path

=head3 templ_path

Returns the C<File::ShareDir->dist_dir> if the app is installed or the
local L<share/templates> dir.

=head2 INSTANCE METHODS

=head3 render

=head3 get_template

Return the template name.

=head3 template_type_error

Throw an exception in exceptional cases ;)

=cut
