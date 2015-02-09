package App::Transfer::Plugin::no_space;

# ABSTRACT: Transfer plugin: no spaces

use 5.010001;
use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

sub no_space {
    my ($self, $p) = @_;
    my ($logfld, $logidx, $field, $text, $len ) = @$p{qw(logfld logidx name value length)};
    return unless $text;
    $text =~ s{\s+}{}gmx;
    return $text;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::no_space - Transfer plugin: 'no_space'

=head1 Interface

=head2 Instance Methods

=head3 C<no_space>

Parameters:

=over

=item C<$logfld> log field name

=item C<$logidx> log field value

=item C<$field>  field name

=item C<$text>   field value

=back

The C<no_space> method remove all space chars (regex: \s+) and returns
the resulting string.

=cut
