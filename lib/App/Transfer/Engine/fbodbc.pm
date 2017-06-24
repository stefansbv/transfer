package App::Transfer::Engine::fbodbc;

# ABSTRACT: The ODBC Firebird RDBMS engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use Regexp::Common;
use namespace::autoclean;

extends 'App::Transfer::Engine';
sub dbh;                                     # required by DBIEngine;
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

        # Set defaults in the URI.
        my $target = $self->target;
        $uri->dbname($ENV{FBSQL_DATABASE})   if !$uri->dbname   && $ENV{FBSQL_DATABASE};
        $uri->host($ENV{FBSQL_HOST})         if !$uri->host     && $ENV{FBSQL_HOST};
        $uri->port($ENV{FBSQL_PORT})         if !$uri->_port    && $ENV{FBSQL_PORT};
        $uri->user($ENV{FBSQL_USER})         if !$uri->user     && $ENV{FBSQL_USER};
        $uri->password($target->password || $ENV{FBSQL_PASSWORD})
            if !$uri->password && ($target->password || $ENV{FBSQL_PASSWORD});

        # Delete the Driver parameter
        # TODO: implement this in URI::db
        my %qp = $uri->query_params;
        delete $qp{Driver} if exists $qp{Driver};

        return DBI->connect($uri->dbi_dsn, scalar $uri->user, scalar $uri->password, {
            %qp,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            FetchHashKeyName => 'NAME_lc',
            LongReadLen      => 524288,
            HandleError => sub {
                my ( $err,  $dbh )  = @_;
                my ( $type, $error ) = $self->parse_error($err);
                my $message
                    = ( $type eq 'errstr' )
                    ? $error
                    : $self->get_message($type);
                hurl fbodbc => __x( $message, name => $error );
                },
        });
    }
);

sub parse_error {
    my ( $self, $err ) = @_;

	say "DBIError: $err" if $self->debug;

    my $message_type
        = $err eq q{} ? "nomessage"
        : $err =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $err =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $err =~ m/\-Token unknown -\s*(.*)/smi         ? "badtoken:$1"
        : $err =~ m/\-Column unknown\s*\-(.*)/smi        ? "colnotfound:$1"
        : $err =~ m/Your user name and password/smi      ? "userpass"
        : $err =~ m/no route to host/smi                 ? "network"
        : $err =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $err =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi ? "driver:$1"
        : $err =~ m/not connected/smi                    ? "notconn"
        :                                                  "unknown";


    my ( $type, $name ) = split /:/x, $message_type, 2;
    return ('errstr', $err) if $type eq "unknown";
    $name = $name ? $name : '';
    $name =~ s{\n\-}{\ }xgsm;                  # cleanup

    return ($type, $name);
}

sub key    { 'fbodbc' }
sub name   { 'fbodbc' }
sub driver { 'DBD::ODBC' }

sub get_info {
    my ($self, $table, $key_field) = @_;

    hurl "The 'table' parameter is required for 'get_info'" unless $table;

    $key_field //= 'name';

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , CASE
                       WHEN r.RDB\$NULL_FLAG IS NULL THEN 1
                       ELSE 0
                      END AS is_nullable
                    , f.RDB\$FIELD_LENGTH AS length
                    , f.RDB\$FIELD_PRECISION AS prec
                    , CASE
                        WHEN f.RDB\$FIELD_SCALE > 0 THEN (f.RDB\$FIELD_SCALE)
                        WHEN f.RDB\$FIELD_SCALE < 0 THEN (f.RDB\$FIELD_SCALE * -1)
                        ELSE 0
                      END AS scale
                    , CASE f.RDB\$FIELD_TYPE
                        WHEN 261 THEN 'blob'
                        WHEN 14  THEN 'char'
                        WHEN 40  THEN 'cstring'
                        WHEN 11  THEN 'd_float'
                        WHEN 27  THEN 'double'
                        WHEN 10  THEN 'float'
                        WHEN 16  THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'int64'
                            ELSE 'numeric'
                          END
                        WHEN 8   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'integer'
                            ELSE 'numeric'
                          END
                        WHEN 9   THEN 'quad'
                        WHEN 7   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'smallint'
                            ELSE 'numeric'
                          END
                        WHEN 12  THEN 'date'
                        WHEN 13  THEN 'time'
                        WHEN 35  THEN 'timestamp'
                        WHEN 37  THEN 'varchar'
                      ELSE 'UNKNOWN'
                      END AS type
                    FROM RDB\$RELATION_FIELDS r
                       LEFT JOIN RDB\$FIELDS f
                            ON r.RDB\$FIELD_SOURCE = f.RDB\$FIELD_NAME
                    WHERE r.RDB\$RELATION_NAME = UPPER('$table')
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref($key_field);
    }
    catch {
        hurl fbodbc => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $flds_ref;
}

sub get_columns {
    my ($self, $table) = @_;

    hurl "The 'table' parameter is required for 'get_columns'" unless $table;

    my $sql = qq(SELECT LOWER(r.RDB\$FIELD_NAME) AS name
                    FROM RDB\$RELATION_FIELDS r
                    WHERE r.RDB\$RELATION_NAME = UPPER('$table')
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $column_list;
    try {
        $column_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        hurl fbodbc => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $column_list;
}

sub table_exists {
    my ( $self, $table ) = @_;

    hurl "The 'table' parameter is required for 'table_exists'" unless $table;

    my $sql = qq(SELECT COUNT(RDB\$RELATION_NAME)
                     FROM RDB\$RELATIONS
                     WHERE RDB\$SYSTEM_FLAG=0
                         AND RDB\$VIEW_BLR IS NULL
                         AND RDB\$RELATION_NAME = UPPER('$table');
    );

    my $val_ret;
    try {
        ($val_ret) = $self->dbh->selectrow_array($sql);
    }
    catch {
        # XXX Wide character in die at .../Throwable.pm line 75. ???
        hurl fbodbc =>
            __x( "XXX Transaction aborted because: {error}", error => $_ );
    };

    return $val_ret;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Engine::fbodbc - Transfer Firebird ODBC engine

=head1 Synopsis

  my $engine = App::Transfer::Engine->load( engine => 'fbodbc' );

=head1 Description

App::Transfer::Engine::fbodbc provides the Firebird ODBC database
engine for Transfer.

=head1 Interface

=head2 Attributes

=head3 dbh

=head2 Instance Methods

=head3 C<parse_error>

Parse and categorize the database error strings.

=head3 C<get_info>

Return a table info hash reference data structure.

=head3 get_columns

Return the column list for the table name provided as parameter.

=head3 C<table_exists>

Return true if the table name provided as parameter exists in the
database.

=head3 table_exists

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
