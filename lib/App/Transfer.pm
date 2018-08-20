package App::Transfer;

# ABSTRACT: Transfer data between files and databases using recipes

use 5.010001;
use utf8;
use Moose;
use MooseX::Types::Path::Tiny qw(Path);
use Moose::Util::TypeConstraints;
use MooseX::App qw(Color Version MutexGroup); #  Depends
use Locale::TextDomain 1.20 qw(App-Transfer);
use Locale::Messages qw(bind_textdomain_filter);
use App::Transfer::X qw(hurl);
use Path::Tiny;
use Log::Any::Adapter;
use Log::Log4perl;

use App::Transfer::Config;

with 'MooX::Log::Any';

Log::Any::Adapter->set('Log4perl');

app_namespace 'App::Transfer::Command';

BEGIN {
    # Borrowed from Sqitch :)
    # Force Locale::TextDomain to encode in UTF-8 and to decode all messages.
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    bind_textdomain_filter 'App-Transfer' => \&Encode::decode_utf8;
}

has 'has_logger' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub {
        return 0;
    },
);

sub _init_logger {
    my $self = shift;
    my $log_fqn = $self->config->log_file_path;
    if ( $log_fqn->is_file ) {
        Log::Log4perl->init( $log_fqn->stringify );
        say "Log file config is '$log_fqn'.\n" if $self->debug;
        $self->log->info("Logging system initialized");
        $self->has_logger(1);
    }
    else {
        warn "The log file config '$log_fqn' was not found, using a default config.\n";
    }
}

sub DEMOLISH {
    my $log_file = App::Transfer::Config::log_file_name;
    unlink $log_file if -f $log_file && -z $log_file;
}

option 'dryrun' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Do not write to the output.],
);

option 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_aliases   => [qw(v)],
    documentation => q[Verbose output.],
);

option 'debug' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_aliases   => [qw(d)],
    documentation => q[Debug output.],
);

option 'show_progress' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_aliases   => [qw(p)],
    documentation => q[Verbose output.],
    default       => sub { 0 },
);

# Not sure if this have to be set globally
# option 'ignorecase' => (
#     is            => 'rw',
#     isa           => 'Bool',
#     cmd_aliases   => [qw(ic)],
#     documentation => q[Ignore case.],
# );

# option 'ignorediacritic' => (
#     is            => 'rw',
#     isa           => 'Bool',
#     cmd_aliases   => [qw(id)],
#     documentation => q[Ignore diacritic.],
# );

has plugins_dir => (
    is       => 'ro',
    isa      => Path,
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

sub emit_literal {
    shift;
    local $|=1;
    print @_;
}

sub comment {
    my $self = shift;
    $self->emit( _prepend '#', @_ );
}

sub comment_literal {
    my $self = shift;
    $self->emit_literal( _prepend '#', @_ );
}

sub debug_print {
    my $self = shift;
    $self->emit( _prepend 'debug:', @_ );    #  if $self->verbose;
}

sub debug_literal {
    my $self = shift;
    $self->emit_literal( _prepend 'debug:', @_ );    # if $self->verbose;
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

###

sub BUILD {
    my $self = shift;
    if ($self->has_logger) {
        $self->_init_logger;
    }
    else {
        my $log4p_conf = q(
            log4perl.rootLogger=DEBUG, SCREEN
            log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
            log4perl.appender.SCREEN.layout=SimpleLayout
            log4perl.appender.SCREEN.Threshold=ERROR
        );
        Log::Log4perl->init(\$log4p_conf);
    }
    return;
}


1;

__END__

=encoding utf8

=head1 Name

App::Transfer - Transfer data between files and databases using recipes

=head1 Interface

=head2 Attributes

=head3 C<dryrun>

The C<dryrun> attribute holds the value of the CLI option C<--dryrun>.

XXX Not used yet.

=head3 C<verbose>

The C<verbose> attribute holds the value of the CLI option C<--verbose>.

=head3 C<plugins_dir>

The C<plugins_dir> attribute holds the value of the plugins directory
from a local project directory.

=head3 C<config>

The L<App::Transfer::Config> object.

=head2 Instance Methods

=head3 C<DEMOLISH>

Remove empty log files at the application shutdown.

=head3 C<emit>

=head3 C<emit_literal>

  $transfer->emit('core.editor=emacs');
  $transfer->emit_literal('Getting ready...');

Send a message to C<STDOUT>, without regard to the verbosity.  Should
be used only if the user explicitly asks for output.

=head3 C<comment>

=head3 C<comment_literal>

  $transfer->comment('On database flipr_test');
  $transfer->comment_literal('Uh-oh...');

Send comments to C<STDOUT>, without regard to the verbosity.  Comments
have C<# > prefixed to every line.  C<comment> appends a newline to
the end of the message while C<comment_literal> does not.

=head3 C<debug_>

=head3 C<debug_literal>

  $transfer->debug('Found snuggle in the crib.');
  $transfer->debug_literal('ITYM "snuggie".');

Send debug information to C<STDOUT> if the C<--verbose> option is set
to true.  Debug messages will have C<debug: > prefixed to every line.
If it's set to false, nothing will be output. C<debug> appends a
newline to the end of the message while C<debug_literal> does not.

=head3 C<vent>

=head3 C<vent_literal>

  $transfer->vent('That was a misage.');
  $transfer->vent_literal('This is going to be bad...');

Send a message to C<STDERR>, without regard to the verbosity.  Should
be used only for error messages to be printed before exiting with an
error, such as when reverting failed changes.  C<vent> appends a
newline to the end of the message while C<vent_literal> does not.

=head3 C<warn>

=head3 C<warn_literal>

  $transfer->warn('Could not find nerble; using nobble instead.');
  $transfer->warn_literal("Cannot read file: $!\n");

Send a warning messages to C<STDERR>.  Warnings will have C<warning: >
prefixed to every line.  Use if something unexpected happened but you
can recover from it.  C<warn> appends a newline to the end of the
message while C<warn_literal> does not.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

David E. Wheeler <david@justatheory.com>

=head1 License

Copyright (c) 2014-2015 Ștefan Suciu

Copyright (c) 2012-2014 iovation Inc.

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
