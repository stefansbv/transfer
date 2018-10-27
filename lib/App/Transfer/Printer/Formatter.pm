package App::Transfer::Printer::Formatter;

# ABSTRACT: Printer

use 5.010001;
use utf8;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use String::Formatter;
use Try::Tiny;
use namespace::autoclean;
use Term::ANSIColor 2.02 qw(colorvalid);
my $encolor = \&Term::ANSIColor::color;

use constant CAN_OUTPUT_COLOR => $^O eq 'MSWin32'
    ? try { require Win32::Console::ANSI }
    : -t *STDOUT;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1 unless CAN_OUTPUT_COLOR;
}

has formatter => (
    is      => 'ro',
    isa     => 'String::Formatter',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return String::Formatter->new({
            input_processor => 'require_named_input',
            string_replacer => 'named_replace',
            codes => {
                s => sub { $_ },
            },
        });
    }
);

sub format {
    my $self = shift;
    local $SIG{__DIE__} = sub {
        die @_ if $_[0] !~ /^Unknown conversion in stringf: (\S+)/;
        hurl format => __x 'Unknown format code "{code}"', code => $1;
    };
    return $self->formatter->format(@_);
}

__PACKAGE__->meta->make_immutable;

1;
