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

has 'tmpl_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return 'recipe';
    },
);

has 'output_path' => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    default => sub {
        return path '.';
    },
);

has 'tmpl_path' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
);

sub render {
    my ( $self, $recipe_data, $output_file ) = @_;
    hurl render => "The output file parameter is required for render."
        unless $output_file;
    my $tt = Template->new(
        INCLUDE_PATH => $self->tmpl_path->stringify,
        OUTPUT_PATH  => $self->output_path->stringify,
    );
    my $template = $self->get_template;
    $tt->process( $template, $recipe_data, $output_file->stringify, binmode => ':utf8' )
        || hurl {
            ident => 'render',
                exitval => 1,
                message => __x( 'Template error: {error}', error => $tt->error() )a,
            };
    return path($self->output_path, $output_file->stringify);
}

sub render_str {
    my ($self, $recipe_data, $output_str) = @_;
    hurl render => "The output_str parameter is required for render_str."
        unless ref $output_str;
    my $tt = Template->new(
        INCLUDE_PATH => $self->tmpl_path->stringify,
        OUTPUT_PATH  => $self->output_path->stringify,
    );
    my $template = $self->get_template;
    $tt->process( $template, $recipe_data, $output_str )
        || hurl {
            ident => 'render',
                exitval => 1,
                message => __x( 'Template error: {error}', error => $tt->error() ),
            };

    return $output_str;
}

sub get_template {
    my $self = shift;
    my $name = $self->tmpl_name;
    $name .= '.tt' unless $name =~ m{\.tt}i;
    return $name;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS



=head1 DESCRIPTION

Generate a file from templates.

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 name

Optional name attribute.  The default value is I<recipe> and is the
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

=cut
