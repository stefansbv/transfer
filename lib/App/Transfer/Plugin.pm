package App::Transfer::Plugin;

# ABSTRACT: The transformation plugin manager

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Moose::Util::TypeConstraints;
use Module::Pluggable::Object;
use App::Transfer::Config;
use Data::Dump qw/dump/;
use namespace::autoclean;

has 'plugins' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_build_plugins',
);

has 'plugin_type' => (
    is       => 'ro',
	isa      => enum( [qw(column_type column row)] ),
    required => 1,
);

# Set min/max depth to load modules exclusive from the plugin_type
# dirs
sub _build_plugins {
	my $self = shift;
    return [
        Module::Pluggable::Object->new(
            min_depth  => 5,
            max_depth  => 5,
            instantiate => 'new',
            search_path => 'App::Transfer::Plugin',
            search_dirs => [ $self->plugin_type ],
        )->plugins,
    ];
};

sub do_transform {
    my ($self, $method, $p) = @_;
    hurl transform => __ "Undefined param in do_transform!"
        unless defined $method;
    my $found = 0;
    for my $plugin ( @{ $self->plugins } ) {
        if ($plugin->can($method)) {
            $found = 1;
            return $plugin->$method($p);
        }
        else {
            next;
        }
    }
    hurl transform => __x( "No plugin for '{method}' in 'do_transform'.",
        method => $method ) if $found == 0;
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin - The transformation plugin manager

=head1 Description

App::Transfer::Plugin manages the plugins and instantiates the
loging module.

=head1 Interface

=head2 Instance Methods

=head3 _build_plugins

Loads the plugins.

=head3 do_transform

Execute the plugin method and pass ths returned value.

=cut
