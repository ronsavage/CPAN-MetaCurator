package CPAN::MetaCurator;

use 5.36.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '1.02';

#-------------------------------------------------

1;

=pod

=head1 How to convert a Perl.Wiki.html into a jsTree

Note:
1: There is assumed to be just 1 item called 'See also' per topic, preferably at the start.
2: There is assumed to be just 1 item containing '<pre>...</pre> per topic. It can appear anywhere within the topic.
3: My web host and I use case-sensitive file systems.

If you wish to download a new version of Perl.Wiki.html:
1. Download and unpack the distro CPAN::MetaCurator from https://metacpan.org/.
2. Download it from http://savage.net.au/.
3. Update Perl.Wiki.html if desired. but note that the format is very strict!
4. Export its data by clicking the 'Tools' tab on the top right:
	a. Choose 'export all'.
	b. Choose 'JSON format' in the pop-up.
	c. The file tiddlers.json will appear in your downloads directory (eg ~/Downloads/ under Debian).
	d. Use tiddlers.json to overwrite the distro's data/cpan.metacurator.tiddlers.json.

If you wish to rebuld the database:
Note: File sizes as of 2025-08-05.
Note: The code shipped can be configured to change the home_path().
1. Optionally, download Perl's 02packages.details.txt and store it in data/. Size: 23,868,403 bytes.
	a. cd ~/perl.modules/CPAN-MetaCurator/data
	b. Download using: wget https://www.cpan.org/modules/02packages.details.txt.gz
	c. Unpack using: gunzip 02packages.details.txt.gz
	Output is: 02packages.details.txt
	d. cd ..
2. If editing the code, do this before the next step:
	a. Empty the log since we don't want to commit it full: cp /dev/null log/development.log
	b. Remove giant file from commit: mv data/02packages.details.txt /tmp
	c. Rebuild the module with: build.module.sh CPAN::MetaCurator 1.02 (or whatever version)
	d. git commit -am"Some commit note..."
	e. Restore giant file: cp /tmp/02packages.details.txt data
3. Run build.db.sh which uses that data to populate the modules table, which contains 268,476 records.
	a. Actually, the code preferentially uses data/modules.table.csv rather than 02packages.details.txt.
	Therefore - before running build.db.sh - hide data/modules.table.csv if you wish to use data/02packages.details.txt.
	The modules.table.csv file was manually exported from an initial run using data/02packages.details.txt.
	b. If I wish to check in new code I run redo.sh rather than build.db.sh.
4. Either way, the code creates data/cpan.metacurator.sqlite. Size: 13,737,984 bytes.
	And outputs html/cpan.metacurator.tree.html.
	And it logs to log/development.log.
6. Delete data/02packages.details.txt since there is no point shipping it.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/CPAN-MetaCurator>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-MetaCurator>.

=head1 Author

Current maintainer: Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

My homepage: L<https://savage.net.au/>.

=head1 License

Perl 5.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
