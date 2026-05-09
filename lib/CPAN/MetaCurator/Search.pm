package CPAN::MetaCurator::Search;

use 5.36.0;
use boolean;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';
use File::Spec;

use Moo;

use Types::Standard qw/Str/;

has module_names_path =>
(
	default		=> sub{return 'data/module.names.txt'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '1.20';

# --------------------------------------------------

sub check
{
	my($self) = @_;

	$self -> logger -> debug("Calling init_config()");
	$self -> init_config;
	$self -> logger -> debug("Calling init_db()");
	$self -> init_db;

	$self -> logger -> debug("Calling build_pad()");
	my($pad)				= $self -> build_pad;
	my($database_path)		= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($module_names_path)	= File::Spec -> catfile($self -> home_path, $self -> module_names_path);

	$self -> logger -> info("Searching modules table");
	$self -> logger -> info("Reading: $database_path");
	$self -> logger -> info("Reading: $module_names_path");

=pod
	my($command)				= `echo ".h on\n.mode csv\nselect * from modules" | sqlite3 $database_path > $modules_csv_path`;
	my($line_count)				= `wc -l $modules_csv_path`;
	my($module_count, $name)	= split(' ', $line_count);
	$module_count--; # Allow for header record.

	$self -> logger -> info("Output record count (excluding header): $module_count");
=cut

} # End of check.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2026, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
