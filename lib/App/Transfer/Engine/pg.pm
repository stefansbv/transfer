package App::Transfer::Engine::pg;

# ABSTRACT: The PostgreSQL engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use Regexp::Common;
use namespace::autoclean;

extends 'App::Transfer::Engine';
sub dbh;                                     # required by DBIEngine;

with 'App::Transfer::Role::SQL' => { ignorecase => 0 };

with qw(App::Transfer::Role::DBIEngine
        App::Transfer::Role::DBIMessages);

has dbh => (
    is      => 'rw',
    isa     => 'DBI::db',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $uri  = $self->uri;
        $self->use_driver;
        my $dsn = $uri->dbi_dsn;
        return DBI->connect($dsn, scalar $uri->user, scalar $uri->password, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            pg_enable_utf8   => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub {
                my ($err, $dbh) = @_;
                my ($type, $name) = $self->parse_error($err);
                say "[EE]:(type=$type) $name" if $self->debug;
                my $message = $self->get_message($type);
                hurl {
                    ident   => "db:$type",
                    message => __x( $message, name => $name ),
                };
            },
        });
    }
);

sub parse_error {
    my ($self, $err) = @_;

    say "[EE] DBI: $err" if $self->debug;

    my $message_type =
         $err eq q{}                                          ? "nomessage"
       : $err =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $err =~ m/column ($RE{quoted}) does not exist/smi    ? "colnotfound:$1"
       : $err =~ m/column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                              ? "colnotfound:$2.$1"
       : $err =~ m/null value in column ($RE{quoted})/smi     ? "nullvalue:$1"
       : $err =~ m/syntax error at or near ($RE{quoted})/smi  ? "syntax:$1"
       : $err =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $err =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $err =~ m/authentication failed .* ($RE{quoted})/smi ? "passname:$1"
       : $err =~ m/no password supplied/smi                   ? "password"
       : $err =~ m/role ($RE{quoted}) does not exist/smi      ? "username:$1"
       : $err =~ m/role ($RE{quoted}) is not permitted to log in/smi      ? "loginforbid:$1"
       : $err =~ m/no route to host/smi                       ? "network"
       : $err =~ m/Key ($RE{balanced}{-parens=>'()'})=($RE{balanced}{-parens=>'()'}) is not present in table ($RE{quoted})/smi    ? "missingfk:$1.$2.$3"
       : $err =~ m/permission denied for relation (\w+)/smi   ? "relforbid:$1"
       : $err =~ m/permission denied for sequence (\w+)/smi   ? "seqforbid:$1"
       : $err =~ m/could not connect to server/smi            ? "servererror"
       : $err =~ m/server not available/smi                   ? "servererror"
       : $err =~ m/Is the server running/smi                  ? "servererror"
       : $err =~ m/not connected/smi                          ? "notconn"
       : $err =~ m/duplicate key value violates unique constraint ($RE{quoted})/smi   ? "duplicate:$1"
       :                                                       "unknown";

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    return ($type, $name);
}

sub key    { 'pg' }
sub name   { 'PostgreSQL' }
sub driver { 'DBD::Pg 2.0' }

sub get_schema_name {
    my ( $self, $table ) = @_;
    my ( $schema_name, $table_name ) = ( undef, $table );
    if ( $table =~ m{\.} ) {
        ( $schema_name, $table_name ) = split /[.]/, $table;
    }
    return ( $schema_name, $table_name );
}

sub get_info {
    my ($self, $table) = @_;

    hurl "The 'table' parameter is required for 'get_info'" unless $table;

    my ($schema_name, $table_name) = $self->get_schema_name($table);

    my $sql = qq( SELECT ordinal_position  AS pos
                    , column_name       AS name
                    , data_type         AS type
                    , column_default    AS defa
                    , is_nullable
                    , character_maximum_length AS length
                    , numeric_precision AS prec
                    , numeric_scale     AS scale
               FROM information_schema.columns
               WHERE table_name = '$table_name'
    );
    $sql .= qq{AND table_schema = '$schema_name'} if $schema_name;
    $sql .=  q{ORDER BY ordinal_position;};

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('name');
    }
    catch {
        hurl pg => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    # Pg has different names for the columns type than Firebird, so we
    # have to map (somehow) the type names to the corresponding plugin
    # method names.
    # TODO!
    my $flds_type = {};
    foreach my $field ( keys %{$flds_ref} ) {
        $flds_type->{$field} = $flds_ref->{$field};
        $flds_type->{$field}{type} = 'varchar'
            if $flds_type->{$field}{type} eq 'character varying';
        $flds_type->{$field}{type} = 'char'
            if $flds_type->{$field}{type} eq 'character';
        $flds_type->{$field}{type} = 'timestamp'
            if $flds_type->{$field}{type} eq 'timestamp without time zone';
        $flds_type->{$field}{type} = 'timestamptz'
            if $flds_type->{$field}{type} eq 'timestamp with time zone';
        $flds_type->{$field}{type} = 'time'
            if $flds_type->{$field}{type} eq 'time without time zone';
        $flds_type->{$field}{type} = 'array'
            if $flds_type->{$field}{type} eq 'ARRAY';
    }

    return $flds_type;
}

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    hurl "The 'table' parameter is required for 'table_keys'" unless $table;

    my ($schema_name, $table_name) = $self->get_schema_name($table);

    my $type = $foreign ? 'FOREIGN KEY' : 'PRIMARY KEY';

    my $sql = qq( SELECT kcu.column_name
                    FROM information_schema.table_constraints tc
                      LEFT JOIN information_schema.key_column_usage kcu
                        ON tc.constraint_catalog = kcu.constraint_catalog
                          AND tc.constraint_schema = kcu.constraint_schema
                          AND tc.constraint_name = kcu.constraint_name
                    WHERE tc.table_name = '$table_name'
                      AND tc.constraint_type = '$type'
    );
    $sql .= qq{AND table_schema = '$schema_name'} if $schema_name;
    $sql .=  q{ORDER BY ordinal_position;};

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $pkf_aref;
    try {
        $pkf_aref = $dbh->selectcol_arrayref($sql);
    }
    catch {
        hurl pg => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $pkf_aref;
}

sub get_columns {
    my ($self, $table) = @_;

    hurl "The 'table' parameter is required for 'get_columns'" unless $table;

    my ($schema_name, $table_name) = $self->get_schema_name($table);

    my $sql = qq( SELECT column_name AS name
               FROM information_schema.columns
               WHERE table_name = '$table_name'
    );
    $sql .= qq{AND table_schema = '$schema_name'} if $schema_name;
    $sql .=  q{ORDER BY ordinal_position;};

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $column_list;
    try {
        $column_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        hurl pg => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $column_list;
}

sub table_exists {
    my ( $self, $table, $or_view ) = @_;

    hurl "The 'table' parameter is required for 'table_exists'" unless $table;

    my ($schema_name, $table_name) = $self->get_schema_name($table);

    my @types = (q{'BASE TABLE'});

    # Allow to also check for views
    push @types, q{'VIEW'} if $or_view;
    my $type_list = join ',', @types;

    my $sql = qq(
         SELECT COUNT(table_name)
             FROM information_schema.tables
             WHERE table_type IN ($type_list)
               AND table_schema NOT IN
               ('pg_catalog', 'information_schema')
               AND table_name = '$table_name'
    );
    $sql .= qq{AND table_schema = '$schema_name'} if $schema_name;
    $sql .= ';';

    my $val_ret;
    try {
        ($val_ret) = $self->dbh->selectrow_array($sql);
    }
    catch {
        hurl pg => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $val_ret;
}

sub table_list {
    my ($self, $schema_name) = @_;

    my $sql = q{ SELECT table_name
                   FROM information_schema.tables
                   WHERE table_type = 'BASE TABLE'
                     AND table_schema NOT IN
                         ('pg_catalog', 'information_schema')
    };
    $sql .= qq{AND table_schema = '$schema_name'} if $schema_name;

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $table_list;
    try {
        $table_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        hurl pg =>
            __x( "Transaction aborted because: {error}", error => $_ );
    };

    return $table_list;
}

sub reset_sequence {
    my ($self, $seq) = @_;
    hurl "The 'seq' parameter is required for 'reset_sequence'" unless $seq;
    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;
    my $val = 1;
    my $para = 'false';                      # for reset
    my $sql = qq{ SELECT setval(?, ?, ?) };
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute($seq, $val, $para);
    }
    catch {
        hurl pg =>
            __x( "Transaction aborted because: {error}", error => $_ );
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Engine::pg - Transfer PostgreSQL engine

=head1 Synopsis

  my $engine = App::Transfer::Engine->load( engine => 'pg' );

=head1 Description

App::Transfer::Engine::pg provides the Pg database engine
for Transfer.  It supports Pg X.X and higher XXX ???.

=head1 Interface

=head2 Attributes

=head3 dbh

=head2 Instance Methods

=head3 C<parse_error>

Parse and categorize the database error strings.

=head3 C<key>

Return the engine key.

=head3 C<name>

Return the engine name.

=head3 C<driver>

Return the DBD driver name.

=head3 C<get_schema_name>

Parse and return the schema name and the table name from the table
parameter.

=head3 C<get_info>

Return a table info hash reference data structure.

=head3 C<table_keys>

Return an array refernece with the table primary key or the foreign
keys when the C<foreign> parameter is set to true.

=head3 C<get_columns>

Return the column list for the table name provided as parameter.

=head3 C<table_exists>

Return true if the table provided as parameter exists in the database.

=head3 table_list

Return the table list in the schema provided as parameter or in the
default schema.

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
