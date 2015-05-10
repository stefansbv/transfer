package App::Transfer::Render;

# ABSTRACT: Render a file from a template

use 5.010001;
use utf8;
use Moose;
use Template;
use File::ShareDir qw(dist_dir);
use Path::Tiny;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use namespace::autoclean;

sub render {
    my ($self, $args) = @_;

    my $type        = $args->{type};
    my $output_file = $args->{output_file};
    my $data        = $args->{data};
    my $output_path = $args->{output_path};
    my $templ_path  = $args->{templ_path}
        // path( dist_dir('App-Transfer'), 'templates' );

    my $template = $self->get_template_for($type);

    $output_file = "${type}$output_file" if $output_file =~ m{^\.};

    my $tt = Template->new(
        INCLUDE_PATH => $templ_path,
        OUTPUT_PATH  => $output_path,
    );

    $tt->process( $template, $data, $output_file, binmode => ':utf8' )
        or die $tt->error(), "\n";

    return $output_file;
}

sub get_template_for {
    my ($self, $type) = @_;

    hurl "The type argument is required" unless defined $type;

    my $template =
         $type eq q{}               ? die("Empty type argument")
       : $type eq 'recipe'          ? 'recipe.tt'
       :                              die("Unknown type $type")
       ;

    return $template;
}

1;

__END__

=head2 render

Generate a file from templates.

Adapted from Tpda3-Devel :)

=head2 get_template_for

Return the template name for one of the two known types: I<config> or
I<recipe>.

=cut
