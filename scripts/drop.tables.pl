#!/usr/bin/env perl

use 5.40.0;

use Data::Dumper::Concise; # For Dumper.

use Getopt::Long;

use CPAN::MetaCurator::Util::Create;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Util::Create
			-> new(home_path => $options{home_path}, log_level => $options{log_level})
			-> drop_all_tables;

} # End of process.

# ------------------------------------------------

say "drop.tables.pl - Drop all tables\n";

my(%options);

$options{help}	 	= 0;
$options{home_path}	= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{log_level}	= 'info';
my(%opts)			=
(
	'help'			=> \$options{help},
	'home_path'		=> \$options{home_path},
	'log_level=s'	=> \$options{log_level},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);
}

exit process(%options);

__END__

=pod

=head1 NAME

drop.tables.pl - Drop all tables

=head1 SYNOPSIS

drop.tables.pl [options]

	Options:
	-help
	-home_path
	-log_level info

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -home_path String

The path to the directory containing data/ and html/.
Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=back

=cut
