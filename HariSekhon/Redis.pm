#!/usr/bin/perl -T
# nagios: -epn
#
#  Author: Hari Sekhon
#  Date: 2013-11-17 00:22:17 +0000 (Sun, 17 Nov 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::Redis;

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;
use Redis;
use Time::HiRes 'time';

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $REDIS_DEFAULT_PORT
                    $database
                    $hostport
                    $precision
                    %redis_options
                    %redis_options_database
                    connect_redis
                )
);
our @EXPORT_OK = ( @EXPORT );

my $slave;

our $REDIS_DEFAULT_PORT = 6379;
our $port               = $REDIS_DEFAULT_PORT;

$password = undef;

our $database;

my $REDIS_DEFAULT_PRECISION = 5;
our $precision = $REDIS_DEFAULT_PRECISION;

our %redis_options = (
    "H|host=s"         => [ \$host,         "Redis Host to connect to" ],
    "P|port=s"         => [ \$port,         "Redis Port to connect to (default: $REDIS_DEFAULT_PORT)" ],
    "p|password=s"     => [ \$password,     "Password to connect with (use if Redis is configured with requirepass)" ],
    "precision=i"      => [ \$precision,    "Number of decimal places for timings (default: $REDIS_DEFAULT_PRECISION)" ],
);

our %redis_options_database = (
    "d|database=s"     => [ \$database,     "Database to select (optional, will default to the default database 0)" ],
);

@usage_order = qw/host port database password warning critical precision/;

sub connect_redis(%){
    my (%params) = @_;
    my $host     = $params{"host"} || croak "no host passed to connect_redis";
    my $port     = $params{"port"} || $REDIS_DEFAULT_PORT;
    my $password = $params{"password"};
    my $host2    = validate_resolvable($host);
    my $hostport = $host2 . ( $verbose ? ":$port" : "" );
    $hostport   .= " ($host)";
    vlog2 "connecting to redis server $hostport";
    my $redis;
    try {
        $redis = Redis->new(server => "$host2:$port", password => $password) || quit "CRITICAL", "failed to connect to redis server $hostport";
    };
    catch_quit "failed to connect to redis server $hostport";
    $redis or quit "CRITICAL", "failed to connect to Redis server $hostport";
    vlog2 "API ping to $hostport\n";
    try {
        $redis->ping || quit "CRITICAL", "API ping to $hostport failed, authentication required?";
    };
    catch_quit "API ping to $hostport failed, authentication required?";
    return ($redis, $hostport);
}

1;