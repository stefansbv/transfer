package App::Transfer::Plugin::varchar;

# ABSTRACT: Transfer plugin for 'varchar' columns

use 5.010001;
use Moose;
use Lingua::Translit 0.23; # for "ISO 8859-16 RON" table
use namespace::autoclean;

with 'MooX::Log::Any';

# Transliteration exmple
has 'latin10' => (
    is      => 'ro',
    isa     => 'Lingua::Translit',
    default => sub {
        return Lingua::Translit->new('ISO 8859-16 RON');
    },
);

sub varchar {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $len ) = @$p{qw(logstr name value length)};
    return unless $text;
    my $str_len = length $text;
    if ($str_len > $len) {
        $self->log->info("$logstr varchar: $field='$text' overflow ($str_len > $len)");
        return;
    }
    return $self->latin10->translit($text);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::varchar - Transfer plugin for 'varchar' columns

=head1 Interface

=head2 Instance Methods

=head3 C<varchar>

Parameters:

=over

=item C<$logstr> log string

=item C<$field>  field name

=item C<$text>   field value

=item C<$len>    field length

=back

The C<varchar> method checks the length of the input text and returns
C<undef> if it's longer than C<$len>, and also creates a log message.
Otherwise returns C<$text>.

=cut
