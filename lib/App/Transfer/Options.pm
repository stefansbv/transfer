package App::Transfer::Options;

# ABSTRACT: Reader and writer options

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use namespace::autoclean;

has transfer => (
    is       => 'ro',
    isa      => 'App::Transfer',
    required => 1,
    handles  => [qw(
        comment
        emit
        debug
        warn
        warn_literal
    )],
);

has 'config' => (
    is      => 'ro',
    isa     => 'App::Transfer::Config',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->transfer->config;
    },
);

has 'recipe' => (
    is      => 'ro',
    isa     => 'App::Transfer::Recipe',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->transfer->recipe;
    },
);

has 'options' => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    default => sub { {} },
);

has 'rw_type' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'target' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {'anonim'},
);

has uri_str => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_db_options',
);

has file => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_file_options',
);

sub _build_file_options {
    my $self = shift;

    my $rw_type = $self->rw_type;
    my ( $opt_file, $file, $section );
    if ( $rw_type eq 'reader' ) {
        $opt_file = 'input_file';
        $section  = 'source';
    }
    elsif ( $rw_type eq 'writer' ) {
        $opt_file = 'output_file';
        $section  = 'destination';
    }
    else {
        hurl options => __x("Unknown reader/writer type");
    }

    # 1. Command line options
    my $opts = $self->options;
    if ( keys $opts ) {

        # 1.1 We have an FILE
        if ( $file = $opts->{$opt_file} ) {
            return $file;
        }
    }

    # 2. Recipe config section
    if ( $file = $self->recipe->$section->file ) {
        return $file->stringify;
    }

    # 3. Configuration files
    # NOT

    hurl options =>
            __x( "Failed to set an FILE option" ) unless $file;
    return;
}

sub _build_db_options {
    my $self = shift;

    my ($uri, $name);                       # URI, target name
    my $rw_type = $self->rw_type;
    my ( $opt_uri, $opt_target, $section );
    if ( $rw_type eq 'reader' ) {
        $opt_uri    = 'input_uri';
        $opt_target = 'input_target';
        $section    = 'source';
    }
    elsif ( $rw_type eq 'writer' ) {
        $opt_uri    = 'output_uri';
        $opt_target = 'output_target';
        $section    = 'destination';
    }
    else {
        hurl options => __x("Unknown reader/writer type");
    }

    # 1. Command line options
    my $opts = $self->options;
    if ( keys $opts ) {

        # 1.1 We have an URI
        if ( $uri = $opts->{$opt_uri} ) {

            # The name is the default
            $self->warn(
                __x( 'The URI option supersede the target option', ) )
                if $opts->{$opt_target};
            return $uri;
        }
        elsif ( $name = $opts->{$opt_target} ) {

            # 1.2 We have a target name, get the URI
            if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
                $self->target($name);
                return $uri;
            }
        }
    }

    # 2. Recipe config section
    if ($name) {

        # We already have a name from CLI
        $self->target($name);
        if ( $uri = $self->recipe->get_uri($name) ) {
            return $uri;
        }
    }
    else {
        # 1.1 Target name from recipe
        if ( $name = $self->recipe->$section->target ) {
            $self->target($name);
            if ( $uri = $self->recipe->get_uri($name) ) {
                return $uri;
            }
        }
    }

    # 3. Configuration files
    if ($name) {

        # We already have a name from CLI or recipe
        $self->target($name);
        if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
            return $uri;
        }
    }
    else {
        if ( $name = $self->config->get( key => "$section.target" ) ) {
            $self->target($name);
            if ( $uri = $self->config->get( key => "target.$name.uri" ) ) {
                return $uri;
            }
        }
    }

    hurl options =>
            __x( "Failed to set an URI option" ) unless $uri;
    return;
}

sub _get_uri_from_config {
    my ($self, $name) = @_;
    my $config = $self->transfer->config;
    return $config->get( key => 'target.' . $name . '.uri' );
}

__PACKAGE__->meta->make_immutable;

1;
