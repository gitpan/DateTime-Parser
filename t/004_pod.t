# -*- perl -*-

# t/004_pod.t - check pod

use Test::Pod tests => 1;

pod_file_ok( "lib/DateTime/Parser.pm", "Valid POD file" );