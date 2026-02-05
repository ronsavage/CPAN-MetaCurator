#!/usr/bin/env perl

use 5.36.0;

use CPAN::MetaCurator::Util::Export;

use Data::Dumper::Concise; # For Dumper().

use Getopt::Long;

use Pod::Usage; # For pod2usage().
# ---------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Util::Export
		-> new(home_path => $options{home_path, packages_txt_path => $options{packages_txt_path},
				log_level => $options{log_level}, packages_csv_path => $options{packages_csv_path})
		-> text2csv;

} # End of process.

# ---------------------------------

say "reformat.02packages.pl - Convert 02packages.details.txt to csv, for quicker importation\n";

my(%options);

$options{help}	 			= 0;
$options{home_path}			= '';
$options{log_level}			= 'debug';
$options{packages_csv_path}	= 'data/02packages.details.txt';
$options{packages_txt_path}	= 'data/02packages.details.csv';
my(%opts)				=
(
	'help'					=> \$options{help},
	'home_path=s'			=> \$options{home_path},
	'log_level=s'			=> \$options{log_level},
	'packages_csv_path=s'	=> \$options{packages_csv_path},
	'packages_txt_path=s'	=> \$options{packages_txt_path},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);

	exit 0;
}

exit process(%options);

__END__

=pod

=head1 NAME

reformat.02packages.pl - Convert 02packages.details.txt to csv, for quicker importation

=head1 SYNOPSIS

reformat.02packages.pl [options]

	Options:
	-help
	-home_path
	-log_level info
	-packages_csv_path Path
	-packages_txt_path Path

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item home_path String

The path to the directory containing data/ and html/. Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item packages_csv_path Path

The path for the output CSV file.

Default: 'data/02packages.details.csv'.

=item packages_txt_path Path

The path for the input txt file.

Default: 'data/02packages.details.txt'.

=back

=cut
