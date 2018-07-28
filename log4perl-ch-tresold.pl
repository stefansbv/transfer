#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Log::Log4perl;

# Log Levels
#   There are six predefined log levels: "FATAL", "ERROR", "WARN", "INFO",
#   "DEBUG", and "TRACE" (in descending priority). Your configured logging
#   level has to at least match the priority of the logging message.

#   If your configured logging level is "WARN", then messages logged with
#   "info()", "debug()", and "trace()" will be suppressed. "fatal()",
#   "error()" and "warn()" will make their way through, because their
#   priority is higher or equal than the configured setting.

my $log4p_conf = q(
    log4perl.rootLogger=DEBUG, SCREEN
    log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.layout=SimpleLayout
    log4perl.appender.SCREEN.Threshold=WARN
);

Log::Log4perl->init(\$log4p_conf);

say "Level from config is WARN";

my $log = Log::Log4perl->get_logger("");

say "is_fatal: ", $log->is_fatal ? 'true' : 'false';
say "is_error: ", $log->is_error ? 'true' : 'false';
say "is_warn : ", $log->is_warn  ? 'true' : 'false';
say "is_info : ", $log->is_info  ? 'true' : 'false';
say "is_debug: ", $log->is_debug ? 'true' : 'false';
say "is trace: ", $log->is_trace ? 'true' : 'false';

say '---';
$log->fatal("fatal msg");
$log->error("error msg");
$log->warn("warn msg");
$log->info("info msg");
$log->debug("debug msg");
$log->trace("trace msg");
say '---';

# Change the treshold
Log::Log4perl->appender_by_name('SCREEN')->threshold('INFO');

$Log::Log4perl::Logger::APPENDER_BY_NAME{SCREEN}->threshold('DEBUG');

say "Level from setting is DEBUG";

say '---';
$log->fatal("fatal msg");
$log->error("error msg");
$log->warn("warn msg");
$log->info("info msg");
$log->debug("debug msg");
$log->trace("trace msg");
say '---';
