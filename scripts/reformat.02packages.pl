#!/usr/bin/env perl

use 5.36.0;

use Data::Dumper::Concise; # For Dumper().

use CPAN::MetaCurator::Util::Import;

use File::Slurper 'read_lines';
# ---------------------------------

say "reformat.02packages.pl - Convert 02packages.details.txt from line-by-line to csv, for quicker importation\n";

binmode STDOUT, ':encoding(UTF-8)';

my($importer)	= CPAN::MetaCurator::Util::Import -> new(home_path => $ENV{HOME});
my(@details)	= read_lines(File::Spec -> catfile($importer -> home_path, $importer -> packages_details_path) );
my($header)		= "package,version";
my($count)		= 0;

say STDOUT 'module,version';

my(@fields);

for (@details)
{
	$count++;

	last if ($count == 10);

	@fields = split(' ', $_);

	say STDOUT "$fields[0],$fields[1]";
}

say "Wrote $count records";
