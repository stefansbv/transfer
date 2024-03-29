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
use Data::Dump qw/ddx/;

with 'MooX::Log::Any';

requires 'dbh';

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
        print "# record:\n";
        ddx $row;
        hurl insert => __x(
            'Insert failed: "{error}"',
            error  => $_,
        );
    };
    return;
}

sub table_truncate {
    my ($self, $table) = @_;
    my ( $stmt );
    try {
        ( $stmt ) = $self->sql->delete( $table );
        $self->dbh->prepare($stmt)->execute();
    }
    catch {
        my $error = $_ =~ s/\n$//gr;
        hurl truncate => __x(
            '[EE] "{table}" table truncate failed: "{error}"',
            error  => $error,
            table  => $table,
        );
    };
    return;
}

sub lookup {
    my ($self, $table, $fields, $where, $attribs) = @_;

    # if ( $attribs->{IGNORECASE} ) {
    #   say 'IGNORECASE=true' if $self->debug;
    #   my $where_new = {};
    #   while ( my ( $key, $value ) = each( %{$where} ) ) {
    #       $where_new->{"upper($key)"} = $value;
    #   }
    #   $where = $where_new;
    # }

    my ( $sql, @bind ) = $self->sql->select( $table, $fields, $where );
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

sub records_aoa {
    my ($self, $table, $fields, $where) = @_;
    hurl dev => 'The "table" parameter is required' unless $table;
    hurl dev => 'The "fields" array ref parameter is required'
        unless ref $fields;
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
    my ($self, $table, $fields, $where, $orderby) = @_;
    hurl dev => 'The "table" parameter is required' unless $table;
    hurl dev => 'The "fields" array ref parameter is required'
        unless ref $fields;
    my ( $sql, @bind ) = $self->sql->select( $table, $fields, $where, $orderby );
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

=encoding utf8

=head1 Name

App::Transfer::Role::DBIEngine - An engine based on the DBI

=head1 Synopsis

  package App::Transfer::Engine::firebird;
  extends 'App::Transfer::Engine';
  with 'App::Transfer::Role::DBIEngine';

=head1 Description

This role encapsulates the common attributes and methods required by
DBI-powered engines.

=head1 Interface

=head2 Instance Methods

=head3 C<begin_work>

=head3 C<finish_work>

=head3 C<rollback_work>

=head3 C<insert>

Build and execute a INSERT SQL statement.

=head3 C<lookup>

Build and execute a SELECT SQL statement and return a limited set of
the results as an array of arays references.

=head3 C<records_aoa>

Build and execute a SELECT SQL statement and return the results as an
array of arays references.

=head3 C<records_aoh>

Build and execute a SELECT SQL statement and return the results as an
array of hash references.

=head1 See Also

=over

=item L<App::Transfer::Engine::pg>

The PostgreSQL engine.

=item L<App::Transfer::Engine::firebird>

The Firebird engine.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
