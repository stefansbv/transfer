package App::Transfer;

# ABSTRACT: Transfer data between files and databases using recipes

use 5.0100;
use utf8;
use Cwd;
use Moose;
use MooseX::Types::Path::Tiny qw(Path File);
use Moose::Util::TypeConstraints;
use MooseX::App qw(Color);
use Path::Class;
use List::Util qw(first);
use Locale::TextDomain 1.20 qw(App::Transfer);
use Locale::Messages qw(bind_textdomain_filter);
use File::Basename;
use App::Transfer::X qw(hurl);

app_namespace 'App::Transfer::Command';

BEGIN {
    # Borrowed from Sqitch :)
    # Force Locale::TextDomain to encode in UTF-8 and to decode all messages.
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    bind_textdomain_filter 'App::Transfer' => \&Encode::decode_utf8;
}

use App::Transfer::Config;
use App::Transfer::Recipe;

option 'dryrun' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Do not write to the output.],
);

option 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Verbose output.],
);

has 'recipe_file' => (
    is       => 'ro',
    isa      => File,
    required => 0,
    coerce   => 1,
);

has plugins_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->top_dir->subdir('plugins')->cleanup;
    },
);

has 'config' => (
    is      => 'ro',
    isa     => 'App::Transfer::Config',
    lazy    => 1,
    default => sub {
        return App::Transfer::Config->new;
    }
);

has 'recipe' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Transfer::Recipe->new(
            recipe_file => $self->recipe_file->stringify,
        );
    },
);


###
# Borrowed from Sqitch :)

sub _prepend {
    my $prefix = shift;
    my $msg = join '', map { $_ // '' } @_;
    $msg =~ s/^/$prefix /gms;
    return $msg;
}

sub emit {
    shift;
    local $|=1;
    say @_;
}

sub comment {
    my $self = shift;
    $self->emit( _prepend '#', @_ );
}

sub debug {
    my $self = shift;
    $self->emit( _prepend 'debug:', @_ ); # if $self->verbosity > 1;
}

sub vent {
    shift;
    my $fh = select;
    select STDERR;
    local $|=1;
    say STDERR @_;
    select $fh;
}

sub vent_literal {
    shift;
    my $fh = select;
    select STDERR;
    local $|=1;
    print STDERR @_;
    select $fh;
}

sub warn {
    my $self = shift;
    $self->vent(_prepend 'warning:', @_);
}

sub warn_literal {
    my $self = shift;
    $self->vent_literal(_prepend 'warning:', @_);
}

# Borrowed from Sqitch :)
###

1;
