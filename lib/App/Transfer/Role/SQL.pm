package App::Transfer::Role::SQL;

# ABSTRACT: SQL Abstract role

use 5.010001;
use utf8;
use MooseX::Role::Parameterized;
use SQL::Abstract;
use namespace::autoclean;

parameter ignorecase => (
    isa      => 'Bool',
    required => 1,
);

role {
	my $p = shift;
	my $ignorecase = $p->ignorecase;

    has 'sql' => (
        is      => 'ro',
        isa     => 'SQL::Abstract',
        default => sub {
            if ($ignorecase) {
				return SQL::Abstract->new( convert => 'upper' );
            }
            else {
                return SQL::Abstract->new;
            }
        },
    );
}

__END__

=encoding utf8

=head1 Name

App::Transfer::Role::SQL

=head1 Synopsis

  with 'App::Transfer::Role::SQL' => { ignorecase => 1 };

=head1 Description

This is a parametrized role used to initialize C<SQL::Abstract> with
the C<convert> option when the C<ignorecase> parameter has a true
value.

=head1 Interface

=head2 Parameters

=head3 C<ignorecase>

The parameter.

=head2 Attributes

=head3 C<sql>

=cut
