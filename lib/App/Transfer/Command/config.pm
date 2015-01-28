package App::Transfer::Command::config;

# ABSTRACT: Configure the application

use 5.010001;
use utf8;

use MooseX::App::Command;
use Moose::Util::TypeConstraints;
use Path::Class ();
use Try::Tiny;
use Locale::TextDomain qw(App-Transfer);
use App::Transfer::X qw(hurl);
use List::Util qw(first);
use namespace::autoclean;

extends qw(App::Transfer);

parameter 'action' => (
    is            => 'rw',
    isa           => enum( [qw(set dump)] ),
    required      => 1,
    documentation => q[Subcommands: set | dump.],
);

has 'context' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $username = getpwuid($<);
        return ( $username eq 'root' ) ? 'global' : 'user';
    },
);

has 'file' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $meth = $self->context . '_file';
        return $self->config->$meth;
    }
);

sub execute {
    my ( $self ) = @_;

    # Set
    if ( $self->action eq 'set' ) {
        say "Not implemented.";
        # $self->create_config($url, $path);
    }

    # dump
    if ( $self->action eq 'dump' ) {
        my %conf = $self->config->dump;
        say "Current config:";
        say " none!" if scalar keys %conf == 0;
        while ( my ( $key, $value ) = each %conf ) {
            print " $key = $value\n";
        }
    }

    return;
}

sub create_config {
    my ($self, $url, $path) = @_;
    if ($path) {
        say "Path = ", $path;
        $self->_set('local.path', $path);
    }
    if ($url) {
        say "URL  = ", $url;
        $self->_set('remote.url', $url);
    }
    return;
}

sub _set {
    my ( $self, $key, $value ) = @_;

    die "Wrong number of arguments."
        if !defined $key || $key eq '' || !defined $value;

    print "Config write to ", $self->file, "...\r";

    try {
        $self->config->set(
            key      => $key,
            value    => $value,
            filename => $self->file,
        );
    }
    catch {
        say "Config write to ", $self->file, "...failed";
        say "[EE] Config: $_";
    };

    say "Config write to ", $self->file, "...done";

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
