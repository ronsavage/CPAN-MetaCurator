#!/usr/bin/env perl

use 5.36.0;

use CPAN::MetaCurator::Util::Import;

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';

use Getopt::Long;

use Pod::Usage; # For pod2usage().
# ---------------------------------

say "reformat.02packages.pl - Convert 02packages.details.txt from line-by-line to csv, for quicker importation\n";

binmode STDOUT, ':encoding(UTF-8)';

my(%options);

$options{help}	 		= 0;
$options{home_path}		= $ENV{HOME};
$options{log_level}		= 'debug';
$options{output_path}	= 'Downloads/02packages.details.csv';
my(%opts)				=
(
	'help'			=> \$options{help},
	'home_path'		=> \$options{home_path},
	'log_level=s'	=> \$options{log_level},
	'output_path=s'	=> \$options{output_path},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);

	exit 0;
}

say 'Working...';

my($importer)	= CPAN::MetaCurator::Util::Import -> new(home_path => $ENV{HOME});
my(@details)	= read_lines(File::Spec -> catfile($importer -> home_path, $importer -> packages_details_path) );
my($header)		= "package,version";
my($count)		= 0;

say STDOUT 'module,version';

my(@fields);

for (@details)
{
	$count++;

	next if ($count < 10);

	last if ($count == 15);

	@fields = split(' ', $_);

	say STDOUT "$fields[0],$fields[1]";
}

say "Wrote $count records";

exit 0;
