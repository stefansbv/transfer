#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Log::Log4perl;
use Log::Log4perl::Level;

# Log Levels
#   There are six predefined log levels: "FATAL", "ERROR", "WARN", "INFO",
#   "DEBUG", and "TRACE" (in descending priority). Your configured logging
#   level has to at least match the priority of the logging message.

#   If your configured logging level is "WARN", then messages logged with
#   "info()", "debug()", and "trace()" will be suppressed. "fatal()",
#   "error()" and "warn()" will make their way through, because their
#   priority is higher or equal than the configured setting.

my $log4p_conf = q(
    log4perl.rootLogger=TRACE, SCREEN
    log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.layout=SimpleLayout
);

Log::Log4perl->init(\$log4p_conf);

my $log = Log::Log4perl->get_logger("");

#$log->level('DEBUG');

say "Level from config is ", $log->level();
$log->inc_level(2);
say "Level from setting is ", $log->level();

say '---';
say "1: is fatal: ", $log->is_fatal ? 'true' : 'false';
say "2: is error: ", $log->is_error ? 'true' : 'false';
say "3: is warn : ", $log->is_warn  ? 'true' : 'false';
say "4: is info : ", $log->is_info  ? 'true' : 'false';
say "5: is debug: ", $log->is_debug ? 'true' : 'false';
say "6: is trace: ", $log->is_trace ? 'true' : 'false';

say '---';
$log->fatal("fatal msg");
$log->error("error msg");
$log->warn("warn msg");
$log->info("info msg");
$log->debug("debug msg");
$log->trace("trace msg");
say '---';

$log->inc_level(1);
say "Level from setting is ", $log->level();

say '---';
$log->fatal("fatal msg");
$log->error("error msg");
$log->warn("warn msg");
$log->info("info msg");
$log->debug("debug msg");
$log->trace("trace msg");
say '---';
