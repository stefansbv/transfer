#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Config::General;

my $conf = Config::General->new(
    -AllowMultiOptions => 1,
    -SplitPolicy       => 'equalsign',
    -Tie               => "Tie::IxHash",
);

# my %where  = (
#     status => undef,
# );
my %where  = (
    user   => 'nwiger',
    status => { '!=', 'completed', -not_like => 'pending%' }
);

say $conf->save_string(\%where);
