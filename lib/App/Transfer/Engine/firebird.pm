package App::Transfer::Engine::firebird;

# ABSTRACT: The firebird engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App::Transfer);
use App::Transfer::X qw(hurl);
use Try::Tiny;
use Regexp::Common;
use namespace::autoclean;

extends 'App::Transfer::Engine';
sub dbh;                                     # required by DBIEngine;
with qw(App::Transfer::Role::DBIEngine
        App::Transfer::Role::Messages);

has dbh => (
    is      => 'rw',
    isa     => 'DBI::db',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $uri  = $self->uri;
        $self->use_driver;
        my $dsn = $uri->dbi_dsn . ';ib_dialect=3;ib_charset=UTF8';
        return DBI->connect($dsn, scalar $uri->user, scalar $uri->password, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            ib_enable_utf8   => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub {
                my ($err, $dbh) = @_;
                my ($type, $name) = $self->parse_error($err);
                my $message = $self->get_message($type);
                hurl firebird => __x( $message, name => $name );
            },
        });
    }
);

sub parse_error {
    my ( $self, $err ) = @_;

    my $message_type
        = $err eq q{} ? "nomessage"
        : $err =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $err =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $err =~ m/\-Token unknown -\s*(.*)/smi         ? "badtoken:$1"
        : $err =~ m/Your user name and password/smi      ? "userpass"
        : $err =~ m/no route to host/smi                 ? "network"
        : $err =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $err =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi ? "driver:$1"
        : $err =~ m/not connected/smi                    ? "notconn"
        :                                                  "unknown";

    my ( $type, $name ) = split /:/x, $message_type, 2;
    $name = $name ? $name : '';
    $name =~ s{\n\-}{\ }xgsm;                  # cleanup

    return ($type, $name);
}

sub key    { 'firebird' }
sub name   { 'Firebird' }
sub driver { 'DBD::Firebird 1.11' }

sub get_info {
    my ($self, $table, $key_field) = @_;

    die "The 'table' parameter is required" unless $table;

    $key_field //= 'name';

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , r.RDB\$NULL_FLAG AS is_nullable
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
        hurl firebird => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $flds_ref;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "The 'table' parameter is required" unless $table;

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
        hurl firebird => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };

    return $val_ret;
}

__PACKAGE__->meta->make_immutable;

1;
