#!/usr/bin/env perl

use 5.36.0;

use Path::Tiny;

# =============

my($perl_file)		= 'data/02packages.details.txt';
my(@lines)			= path($perl_file)->lines_utf8;
my($modules_file)	= 'data/modules.table.csv';
my($count)			= 0;

open(my $io, '>:encoding(UTF-8)', $modules_file) || die "Can't open($modules_file): $!\n";
print $io "name,version\n";

my(@fields);

for (@lines)
{
	@fields = split(/\s+/, $_);

	next if (! $fields[0]); # Skip blank lines.
	next if ($fields[0] =~ /:$/); # Skip header.

	print $io "$fields[0],$fields[1]\n";
}

close $io;
