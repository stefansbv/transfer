package App::Transfer::Role::Utils;

# ABSTRACT: Role for utility functions

use 5.0100;
use utf8;
use Moose::Role;

sub sort_hash_by_pos {
    my ( $self, $attribs ) = @_;

    #-- Sort by pos
    #- Keep only key and pos for sorting
    my %temp = map { $_ => $attribs->{$_}{pos} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return wantarray ? @attribs : \@attribs;
}

sub trim {
    my ( $self, @text ) = @_;
    for (@text) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @text : "@text";
}

no Moose::Role;

1;

=head2 sort_hash_by_pos

Use ST to sort hash by value (pos), returns an array or an array
reference of the sorted items.

=cut
