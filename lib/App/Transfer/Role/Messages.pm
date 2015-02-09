package App::Transfer::Role::Messages;

# ABSTRACT: Database engines error messages

use 5.0100;
use utf8;
use Moose::Role;
use Locale::TextDomain 1.20 qw(App-Transfer);

has '_messages' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => undef,
    default  => sub {
        return {
            badtoken    => 'token unknown: {name}',
            checkconstr => 'check: {name}',
            colnotfound => 'column not found {name}',
            dbnotfound  => 'database {name} not found',
            driver      => 'database driver {name} not found',
            duplicate   => 'duplicate {name}',
            nethost     => 'network problem with host {name}',
            network     => 'network problem',
            notconn     => 'not connected',
            nullvalue   => 'null value for {name}',
            passname    => 'authentication failed for {name}',
            password    => 'authentication failed, password?',
            relforbid   => 'permission denied',
            relnotfound => 'relation {name} not found',
            syntax      => 'SQL syntax error',
            unknown     => 'database error',
            username    => 'wrong user name: {name}',
            userpass    => 'authentication failed',
            servererror => 'server not available',
        };
    },
    handles => { get_message => 'get', },
);

no Moose::Role;

1;
