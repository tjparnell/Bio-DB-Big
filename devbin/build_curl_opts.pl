#!/usr/bin/env perl

=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

use strict;
use warnings;

# USAGE: ./build_curl_opts.pl /path/to/curl > lib/Bio/DB/Big/CurlOpts.pm
#
# DESC: Used to build a hash of CURLOPTs from the CURL source code into a Perl module. The 
# values are ints and can be later used to control the underlyiing CURL behaviour

my $curl_headers = $ARGV[0];

die "No directory given" if(! defined $curl_headers);
die 'Cannot find a directory at '.$curl_headers if( ! -d $curl_headers);

my $curl_h = "${curl_headers}/include/curl/curl.h";
die "Cannot find curl headers at expected path $curl_h" if(! -f $curl_h);

my $curl_version = q{};
{
  local $/ = undef;
  my $file = "${curl_headers}/include/curl/curlver.h";
  open(my $fh, '<', $file) or die "Cannot open '$file': $!";
  my $content = <$fh>;
  close $fh;
  if($content =~ /#define LIBCURL_VERSION "(.+?)"/) {
    $curl_version = $1;
  }
  else {
    die "Cannot get curl version from LIBCURL_VERSION in curlver.h";
  }
}

my $content = `cpp $curl_h 2>&1`;
my $opt_hash = {};
my @keys;
while($content =~ /CURLOPT_\s([A-Z_]+)\s=([\s0-9+]+)/g) {
  my $opt = "CURLOPT_${1}";
  my $value = eval $2;
  $opt_hash->{$opt} = $value;
  push(@keys, $opt);
}

my $date = `date`;
chomp $date;

print <<EOF;
=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::DB::Big::CurlOpts;
use strict;
use warnings;

use base 'Exporter';

=pod

=head1 NAME

Bio::DB::Big::CurlOpts

=head1 SYNOPSIS

    use Bio::DB::Big::CurlOpts;
    my \$timeout_value = CURLOPT_TIMEOUT_MS;

=head1 DESCRIPTION

An autogenerated file of CURL options to be used to influence the underlying CURL library used by bigWigLib. These have been taken from the curl.h header and parsed into this Perl module.

B<DO NOT EDIT THIS FILE YOURSELF>

=head1 GENERATED ON

This module was last generated on ${date} using CURL version ${curl_version}.

=cut

EOF

# Do the printing of the opts into the constants
print 'our @EXPORT = qw('.join(q{ }, @keys).');';
print <<EOF;


use constant {
EOF

foreach my $opt (@keys) {
  printf("\t%s => %d,\n", ${opt}, $opt_hash->{$opt});
}
print "};

";

print <<'EOF';

=pod

=head1 AVAILABLE OPTS

Below is the list of options that are available through this module. See L<https://curl.haxx.se/libcurl/c/curl_easy_setopt.html> for more information on what these options do.

=over 8

EOF

foreach my $opt (@keys) {
  print "=item $opt\n\n";
}

print <<EOF;
=back

=cut

1;

EOF
