package App::Transfer::Role::DBIEngine;

# ABSTRACT: DBI engine role

use 5.010001;
use utf8;
use Moose::Role;
use DBI;
use Try::Tiny;
use App::Transfer::X qw(hurl);
use Locale::TextDomain qw(App-Transfer);
use SQL::Abstract;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

requires 'dbh';

has 'sql' => (
    is => 'ro',
    isa => 'SQL::Abstract',
    default => sub {
        return SQL::Abstract->new;
    },
);

sub begin_work {
    my $self = shift;
    $self->dbh->begin_work;
    return $self;
}

sub finish_work {
    my $self = shift;
    $self->dbh->commit;
    return $self;
}

sub rollback_work {
    my $self = shift;
    $self->dbh->rollback;
    return $self;
}

sub insert {
    my ($self, $table, $row) = @_;
    my ( $stmt, @bind );
    try {
        ( $stmt, @bind ) = $self->sql->insert( $table, $row );
        $self->dbh->prepare($stmt)->execute(@bind);
    }
    catch {
        print "EE: $_\n";                    # XXX
        hurl insert => __x(
            'Insert failed: "{error}" for record "{record}"',
            error  => $_,
            record => join '|', map { $_ || q( ) } @bind,
        );
    };
    return;
}

sub lookup {
    my ($self, $table, $fields, $where) = @_;
    my $ary_ref;
    try {
        my ( $stmt, @bind ) = $self->sql->select( $table, $fields, $where );
        my $args = { MaxRows => 10 };    # limit search result
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        hurl insert => __x('Select failed: {error}', error => $_);
    };
    return $ary_ref;
}

sub records_aoa {
    my ($self, $table, $fields, $where) = @_;
    die "The 'table' parameter is required" unless $table;
    $fields //= '*';                         # or all fields
    my $ary_ref;
    try {
        my ( $stmt, @bind ) = $self->sql->select( $table, $fields, $where );
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, undef, @bind );
    }
    catch {
        hurl insert => __x('Select failed: {error}', error => $_);
    };
    return $ary_ref;
}

sub records_aoh {
    my ($self, $table, $fields, $where, $order) = @_;
    die "The 'table' parameter is required" unless $table;
    $fields //= '*';                         # or all fields
    my ( $sql, @bind ) = $self->sql->select( $table, $fields, $where, $order );
    my @records;
    try {
        my $sth = $self->dbh->prepare($sql);
        $sth->execute(@bind);
        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        hurl insert => __x('Select failed: {error}', error => $_);
    };
    return \@records;
}

no Moose::Role;

1;

__END__

=head1 Name

App::Transfer::Command::checkout - An engine based on the DBI

=head1 Synopsis

  package App::Transfer::Engine::sqlite;
  extends 'App::Transfer::Engine';
  with 'App::Transfer::Role::DBIEngine';

=head1 Description

This role encapsulates the common attributes and methods required by
DBI-powered engines.

=head1 Interface

=head1 See Also

=over

=item L<App::Transfer::Engine::pg>

The PostgreSQL engine.

=item L<App::Transfer::Engine::firebird>

The Firebird engine.

=back

=head1 Authors

David E. Wheeler <david@justatheory.com>

Ştefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of that software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and that permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
