package App::Transfer::Recipe::Datasource;

# ABSTRACT: Recipe datasources section

use 5.010001;
use Moose;
use namespace::autoclean;

has '_valid_elts' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => 'valid_elts',
    default  => sub { {} },
    handles  => {
        get_valid_list => 'get',
    },
);

has '_non_valid_elts' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => 'non_valid_elts',
    default  => sub { {} },
    handles  => {
        get_non_valid_list => 'get',
    },
);

has '_hints' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    traits   => ['Hash'],
    init_arg => 'hints',
    default  => sub { {} },
    handles  => {
        get_hints => 'get',
    },
);

has '_datasource' => (
    is       => 'ro',
    isa      => 'HashRef[ArrayRef]',
    traits   => ['Hash'],
    init_arg => 'datasource',
    default  => sub { {} },
    handles  => {
        get_ds => 'get',
    },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my @args  = @_;

    $args[0]->{hints} = ds_to_hoh( $args[0]->{hints}, 'hint' )
        if exists $args[0]->{hints};

    $args[0]->{datasource} = ds_to_hoaoh( $args[0]->{datasource}, 'code' )
        if exists $args[0]->{datasource};

    $args[0]->{valid_elts} = ds_to_hoa( $args[0]->{valid_elts} )
        if exists $args[0]->{valid_elts};

    $args[0]->{non_valid_elts} = ds_to_hoa( $args[0]->{non_valid_elts} )
        if exists $args[0]->{non_valid_elts};

    return $class->$orig(@args);
};

sub ds_to_hoh {
    my ($args, $key_name) = @_;
    my $args_hoh = {};
    foreach my $key ( keys %{$args} ) {
        if ( ref $args->{$key}{record} eq 'ARRAY' ) {
            foreach my $rec ( @{ $args->{$key}{record} } ) {
                $args_hoh->{$key}{ $rec->{item} } = $rec->{$key_name};
            }
        }
        else {
            $args_hoh->{$key}{ $args->{$key}{record}{item} }
                = [ $args->{$key}{record}{$key_name} ];
        }
    }
    return $args_hoh;
}

sub ds_to_hoa {
    my ($args) = @_;
    my $args_hoh = {};
    foreach my $key (keys %{$args}) {
        if (ref $args->{$key}{item} eq 'ARRAY') {
            $args_hoh->{$key} = $args->{$key}{item};
        }
        else {
            $args_hoh->{$key} = [ $args->{$key}{item} ];
        }
    }
    return $args_hoh;
}

sub ds_to_hoaoh {
    my ( $args, $key_name ) = @_;
    my $ds = {};
    foreach my $key ( keys %{$args} ) {
        $ds->{$key} = [];
        if ( ref $args->{$key}{record} eq 'ARRAY' ) {
            foreach my $rec ( @{ $args->{$key}{record} } ) {
                push @{ $ds->{$key} }, { $rec->{item} => $rec->{$key_name} };
            }
        }
        else {
            push @{ $ds->{$key} },
                { $args->{$key}{record}{item} =>
                    $args->{$key}{record}{$key_name} };
        }
    }
    return $ds;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Recipe::Datasource - Recipe datasources section

=head1 Synopsis

=head1 Description

=head1 Interface

=head2 Constructors

=head2 Attributes

=head3 C<_valid_elts>

A hash reference attribute for the C<_valid_elts> section.

=head3 C<_non_valid_elts>

A hash reference attribute for the C<_non_valid_elts> section.

=head3 C<_hints>

A hash reference of hash references attribute for the C<hints>
section.

=head3 C<_datasource>

A hash reference of array references attribute for the C<datasource>
section.

=head2 Instance Methods

XXX Make coercions for this!?

=head3 C<ds_to_hoh>

=head3 C<ds_to_hoa>

=head3 C<ds_to_hoaoh>

=cut
