package App::Transfer::Plugin::column::numeric_format;

# ABSTRACT: clean decimals

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooX::Log::Any';

sub numeric_format {
    my ( $self, $p ) = @_;
    my ($logstr, $field, $value, $len ) = @$p{qw(logstr name value length)};
    return unless defined $value;
    $value =~ s{\.}{}gmx;
    if ( $value =~ m{,(?:\d{1,2})}mx ) {
        $value =~ s{,}{.}mx;
    }
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;
