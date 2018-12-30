# Test for the Render module

use 5.010;
use utf8;
use Test2::V0;
use Path::Tiny;
use Data::Dump;

use App::Transfer::DBFInfo;

my $input_file = path 't', 'DBF_TYPE.DBF';

my $cols_meta = [
    qw{
        F_CHAR
        F_INT
        F_NUM
        F_FLOAT
        F_DATE
        F_BOOL
        F_MEMO
        F_GEN
        }
];

my $stru_meta = {
    F_BOOL => {
        length => 1,
        name   => "F_BOOL",
        pos    => 6,
        prec   => undef,
        scale  => 0,
        type   => "bool"
    },
    F_CHAR => {
        length => 10,
        name   => "F_CHAR",
        pos    => 1,
        prec   => undef,
        scale  => 0,
        type   => "varchar",
    },
    F_DATE => {
        length => 8,
        name   => "F_DATE",
        pos    => 5,
        prec   => undef,
        scale  => 0,
        type   => "date"
    },
    F_FLOAT => {
        length => 10,
        name   => "F_FLOAT",
        pos    => 4,
        prec   => undef,
        scale  => 2,
        type   => "float"
    },
    F_GEN => {
        length => 10,
        name   => "F_GEN",
        pos    => 8,
        prec   => undef,
        scale  => 0,
        type   => "G"
    },
    F_INT => {
        length => 10,
        name   => "F_INT",
        pos    => 2,
        prec   => undef,
        scale  => 0,
        type   => "numeric",
    },
    F_MEMO => {
        length => 10,
        name   => "F_MEMO",
        pos    => 7,
        prec   => undef,
        scale  => 0,
        type   => "text"
    },
    F_NUM => {
        length => 10,
        name   => "F_NUM",
        pos    => 3,
        prec   => undef,
        scale  => 2,
        type   => "numeric",
    },
};

my $cols_info = {
    id => {
        pos    => 1,
        name   => 'id',
        type   => 'integer',
        length => 2,
        prec   => undef,
        scale  => undef,
    },
    den => {
        pos    => 1,
        name   => 'den',
        type   => 'varchar',
        length => 20,
        prec   => undef,
        scale  => undef,
    },
};

my $dbf  = App::Transfer::DBFInfo->new( input_file => $input_file );

is $dbf->get_columns, $cols_meta, 'ge columns';

is $dbf->_structure_meta, $stru_meta, 'get structure';

done_testing;
