package App::Transfer::Plugin::row::lookup_in_ds;

# ABSTRACT: Transfer plugin: lookup in data source

use 5.010001;
use Moose;
use List::Util qw/any/;
use Lingua::Translit 0.23; # for "Common RON" table
use namespace::autoclean;

with 'MooX::Log::Any';

# Transliteration
has 'common_RON' => (
    is      => 'ro',
    isa     => 'Lingua::Translit',
    default => sub {
        return Lingua::Translit->new('Common RON');
    },
);

sub lookup_in_ds {
    my ( $self, $p ) = @_;
    my ( $logstr, $field, $text, $lookup_table, $valid_list, $attribs)
        = @$p{qw(logstr field_src value lookup_table valid_list attributes)};
    return unless $text;

    my $text_orig = $text;
    
    # Return the value (text) if is in the valid list
    if ( $valid_list ) {
        return $text if any { $text eq $_ } @{$valid_list};
    }

    # Attributes - ignore diacritics
    if ( $attribs->{IGNOREDIACRITIC} ) {
        $text = $self->common_RON->translit($text);
    }

    # Attributes - ignore case
    if ( $attribs->{IGNORECASE} ) {
        $text = lc $text;
    }

    # Lookup
    if ( $attribs->{REGEX} ) {
        foreach my $rec ( @{$lookup_table} ) {
            foreach my $key ( keys %{$rec} ) {
                return $rec->{$key} if $text =~ m/${key}/i;
            }
        }
        $self->log->info("$logstr regex lookup: failed for '$field'='$text'");
        return '';
    }
    else {
        foreach my $rec ( @{$lookup_table} ) {
            foreach my $key ( keys %{$rec} ) {
                return $rec->{$key} if $text eq $key;
            }
        }
        $self->log->info("$logstr lookup: failed for '$field'='$text'");
        return $text_orig;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Plugin::lookup_in_ds - lookup in datasources

=head1 Interface

=head2 Instance Methods

=head3 C<lookup_in_ds>

Parameters:

=over

=item C<logstr> log string

Used for identifying the source row data.  It is a string like: "[recno=143"

=item C<field>        the source field, used for the log

=item C<lookup_table> a AoH dictionary table

=item C<valid_list attributes> a AoH dictionary table

=item C<attributes>

The attributes can be used to alter the default behaviour of the
plugin.

Valid attributes are: IGNORECASE, IGNOREDIACRITIC and REGEX.

The first two match the keys in the dictionary even when the case is
different and there are diacritics in the text.

The other uses a regex for match instead of the 'eq' function.

=item C<text>         the value to lookup


=back

=cut
