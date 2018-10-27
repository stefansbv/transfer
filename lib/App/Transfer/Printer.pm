package App::Transfer::Printer;

# ABSTRACT: Printer

use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Moose;
use App::Transfer::Printer::Formatter;

has '_format' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[Str]',
    default   => sub {
        return {
            '2i2c_ll' => qq(  %-27{label}s  %-27{descr}s\n),
            '0i2c_rl' => qq(%29{label}s  %-27{descr}s\n),
            '2i1c_l_' => qq(  %-27{label}s\n),   # 2sp_ident, 1col, left_just
            '4i1c_l_' => qq(    %-27{label}s\n), # 4sp_ident, 1col, left_just
        };
    },
    handles   => {
        get_format => 'get',
    },
);

has formatter => (
    is       => 'ro',
    isa      => 'App::Transfer::Printer::Formatter',
    lazy     => 1,
    default  => sub { App::Transfer::Printer::Formatter->new },
);

sub printer {
    my ( $self, $format_name, $data_href ) = @_;
    my $formatter = $self->formatter;
    my $format    = $self->get_format($format_name);
    hurl format => __x( "Format name '{name}' not found!", name => $format_name )
      if !$format;
    $self->page( $formatter->format( $format, $data_href ) );
    return;
}

sub page {
    my $self = shift;
    return print @_;
}

1;
