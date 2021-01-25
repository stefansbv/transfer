package App::Transfer::Recipe::Hints;

# ABSTRACT: Recipe datasources hints section

use 5.010001;
use Moose;
use Lingua::Translit 0.23;
use namespace::autoclean;

has 'common_RON' => (
    is      => 'ro',
    isa     => 'Lingua::Translit',
    default => sub {
        return Lingua::Translit->new('Common RON');
    },
);

has 'ignorediacritic' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub {
        0;
    },
);

has 'ignorecase' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub {
        0;
    },
);

has '_hints_data' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    traits   => ['Hash'],
    init_arg => 'hints',
    default  => sub { {} },
    handles  => {
        get_hints_for => 'get',
        all_hints     => 'keys',
    },
);

has '_hints' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    traits   => ['Hash'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_hints',
    handles  => {
        get_hint => 'get',
    },
);

sub _build_hints {
    my $self  = shift;
    my $hints = {};
    foreach my $hint_name ( $self->all_hints ) {
        my $hint = $self->get_hints_for($hint_name);
        foreach my $key ( keys %{$hint} ) {
            my $old_key = $key;
            $key = $self->common_RON->translit($key)
                if $self->ignorediacritic;
            $key = lc $key
                if $self->ignorecase;
            $hints->{$hint_name}{$key} = $hint->{$old_key};
        }
    }
    return $hints;
}

sub get_hint_for {
    my ( $self, $name, $value ) = @_;
    $value = $self->common_RON->translit($value) if $self->ignorediacritic;
    $value = lc $value if $self->ignorecase;
    if ( my $hint = $self->get_hint($name) ) {

        return $hint->{$value};
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis


=head1 Description


=head1 Interface

=head2 Attributes

=head3 common_RON

Instantiates and returns a C<Lingua::Translit> object with the 'Common
RON' transliteration table; This table maps the Romanian letters with
diacritical marks to the equivalent, by convention, letters without
diacritical marks.

=head3 ignorediacritic

When this attribute is set to true, the diacritics are ignored.

=head3 ignorecase

When this attribute is set to true, the case is ignored.

=head3 _hints_data

The C<hints> data-structure read from the C<datasources> sections.

=head3 _hints

Anoter data-structure...

=head2 Instance Methods

=head3 _build_hints

=head3 get_hint_for

=cut
