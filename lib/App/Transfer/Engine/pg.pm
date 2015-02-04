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
                my $message = $self->get_message($type);
                hurl pg => __x( $message, name => $name );
            },
        });
    }
);

sub parse_error {
    my ($self, $err) = @_;

    my $message_type =
         $err eq q{}                                          ? "nomessage"
       : $err =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $err =~ m/column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                              ? "colnotfound:$2.$1"
       : $err =~ m/null value in column ($RE{quoted})/smi     ? "nullvalue:$1"
       : $err =~ m/syntax error at or near ($RE{quoted})/smi  ? "syntax:$1"
       : $err =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $err =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $err =~ m/authentication failed .* ($RE{quoted})/smi ? "passname:$1"
       : $err =~ m/no password supplied/smi                   ? "password"
       : $err =~ m/role ($RE{quoted}) does not exist/smi      ? "username:$1"
       : $err =~ m/no route to host/smi                       ? "network"
       : $err =~ m/Key ($RE{balanced}{-parens=>'()'})=/smi    ? "duplicate:$1"
       : $err =~ m/permission denied for relation/smi         ? "relforbid"
       : $err =~ m/could not connect to server/smi            ? "servererror"
       : $err =~ m/not connected/smi                          ? "notconn"
       :                                                       "unknown";

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    return ($type, $name);
}

sub key    { 'pg' }
sub name   { 'PostgreSQL' }
sub driver { 'DBD::Pg 2.0' }

sub get_info {
    my ($self, $table) = @_;

    my $sql = qq( SELECT ordinal_position  AS pos
                    , column_name       AS name
                    , data_type         AS type
                    , column_default    AS defa
                    , is_nullable
                    , character_maximum_length AS length
                    , numeric_precision AS prec
                    , numeric_scale     AS scale
               FROM information_schema.columns
               WHERE table_name = '$table'
               ORDER BY ordinal_position;
    );

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
    }

    return $flds_type;
}

sub table_exists {
    my ( $self, $table ) = @_;

    my $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$table';
    );

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

__PACKAGE__->meta->make_immutable;

1;
