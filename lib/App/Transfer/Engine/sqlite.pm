package App::Transfer::Engine::sqlite;

# ABSTRACT: The SQLite engine

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
        my $dbname = $uri->dbname;
        # my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname);
        my $dbfile = $dbname;
        $uri->dbname($dbfile);
        my $dsn = $uri->dbi_dsn;
        return DBI->connect($dsn, undef, undef, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            sqlite_unicode   => 1,
            sqlite_use_immediate_transaction => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub {
                my ($err, $dbh) = @_;
                my ($type, $name) = $self->parse_error($err);
                my $message = $self->get_message($type);
                hurl {
                    ident   => "db:$type",
                    message => __x( $message, name => $name ),
                };

            },
            Callbacks        => {
                connected => sub {
                    my $dbh = shift;
                    $dbh->do('PRAGMA foreign_keys = ON');
                    return;
                },
            },
        });
    }
);

sub parse_error {
    my ($self, $err) = @_;

    say "DBIError: $err" if $self->debug;
    
    my $message_type =
         $err eq q{}                                        ? "nomessage"
       : $err =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $err =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $err =~ m/not connected/smi                        ? "notconn"
       : $err =~ m/Field ($RE{quoted}) does not exist/smi   ? "colnotfound:$1"
       : $err =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                       "unknown";
    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';
    return ($type, $name);
}

sub key    { 'sqlite' }
sub name   { 'SQLite' }
sub driver { 'DBD::SQLite' }

sub get_info {
    my ($self, $table, $key_field) = @_;

    hurl "The 'table' parameter is required for 'get_info'" unless $table;

    $key_field ||= 'name';

    my $h_ref = $self->dbh
        ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );
    my $flds_ref = {};

    foreach my $cid ( sort keys %{$h_ref} ) {
        my $name       = $h_ref->{$cid}{name};
        my $dflt_value = $h_ref->{$cid}{dflt_value};
        my $notnull    = $h_ref->{$cid}{notnull};
        # my $pk       = $h_ref->{$cid}{pk}; is part of PK ? index : undef
        my $data_type  = $h_ref->{$cid}{type};

        # Parse type;
        my ($type, $precision, $scale);
        if ( $data_type =~ m{
               (\w+)                           # data type
               (?:\((\d+)(?:,(\d+))?\))?       # optional (precision[,scale])
             }x
         ) {
            $type      = $1;
            $precision = $2;
            $scale     = $3;
        }
        my $info = {
            pos         => $cid,
            name        => $name,
            type        => $type,
            is_nullable => $notnull ? 0 : 1,
            defa        => $dflt_value,
            length      => $precision,
            prec        => $precision,
            scale       => $scale,
        };
        $flds_ref->{ $info->{$key_field} } = $info;
    }

    return $flds_ref;
}

sub table_keys {
    my ( $self, $table, $foreign ) = @_;
    hurl "The 'table' parameter is required for 'table_keys'" unless $table;
    return $self->_table_keys_foreign($table) if $foreign;
    my @names = $self->dbh->primary_key(undef, undef, $table);
    return \@names;
}

sub _table_keys_foreign {
    my ( $self, $table ) = @_;
    hurl "The 'table' parameter is required for 'table_keys_foreign'" unless $table;
    my $h_ref = $self->dbh
        ->selectall_hashref( "PRAGMA foreign_key_list($table)", 'id' );
    my @names = map { $h_ref->{$_}{from} } keys %{$h_ref};
    return \@names;
}

sub get_columns {
    my ( $self, $table ) = @_;
    hurl "Missing required arguments: table" unless $table;
    my $dbh = $self->dbh;
    my $h_ref = $dbh ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );
    my $column_list;
    foreach my $cid ( sort keys %{$h_ref} ) {
        push @{$column_list}, $h_ref->{$cid}{name};
    }
    return $column_list;
}

sub table_exists {
    my ( $self, $table ) = @_;
    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );
    my $val_ret;
    try {
        ($val_ret) = $self->dbh->selectrow_array($sql);
    }
    catch {
        hurl sqlite => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };
    return $val_ret;
}

sub table_list {
    my $self = shift;
    my $sql = qq( SELECT name
                FROM sqlite_master
                WHERE type = 'table';
    );
    my $table_list;
    try {
        $table_list = $self->dbh->selectcol_arrayref($sql);
    }
    catch {
        hurl sqlite => __x(
            'Transaction aborted because: {error}',
            error    => $_,
        );
    };
    return $table_list;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

App::Transfer::Engine::sqlite - Transfer PostgreSQL engine

=head1 Synopsis

  my $engine = App::Transfer::Engine->load( engine => 'sqlite' );

=head1 Description

App::Transfer::Engine::sqlite provides the Sqlite database engine
for Transfer.  It supports Sqlite X.X and higher XXX ???.

=head1 Interface

=head2 Instance Methods

=head3 dbh

=head3 parse_error

Parse and categorize the database error strings.

=head3 key

=head3 name

=head3 driver

=head3 get_info

Return a table info hash reference data structure.

=head3 table_keys

=head3 _table_keys_foreign

=head3 get_columns

=head3 table_exists

Return true if the table provided as parameter exists in the database.

=head3 table_list

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
