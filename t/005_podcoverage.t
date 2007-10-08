# -*- perl -*-

# t/004_podcoverage.t - check pod

use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "DateTime::Parser", "POD is covered" );