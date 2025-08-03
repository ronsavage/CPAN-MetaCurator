package CPAN::MetaCurator;

use 5.36.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '1.01';

#-------------------------------------------------

1;

=pod

=head1 How to convert a Perl.Wiki.html into a jsTree

Note: My web host and I use case-sensitive file systems
Download Perl.Wiki.html from http://savage.net.au/
Download and unpack the distro CPAN::MetaCurator from https://metacpan.org/
Update Perl.Wiki.html if desired
Export its data by clicking the Tools tab on the top right:
1: Choose 'export all'
2: Choose 'JSON format' in the pop-up
3: The file tiddlers.json will appear in your downloads directory (eg ~/Downloads/ under Debian)
4: Move tiddlers.json into the distro's data/ as cpan.metacurator.tiddlers.json to replace the copy shipped with the distro
Run scripts/build.db.sh. This runs:
1: scripts/drop.tables.pl
2: scripts/create.tables.pl
3: scripts/populate.sqlite.tables.pl
This reads data/cpan.metacurator.tiddlers.json and outputs data/cpan.metacurator.sqlite
4: scripts/export.as.tree.pl
This reads data/cpan.metacurator.sqlite and outputs html/cpan.metacurator.tree.html
The code shipped can be configured to change the home_path()
And it logs to log/development.log

Note: Development process
1: Download Perl's 02packages.details.txt and store it in data/. Size: 23,868,403.
2: Run buid.db.sh which uses that data to populate the modules table, which contains 268,476 records (2025-07-28).
	The code preferentially uses data/modules.table.csv rather than 02packages.details.txt.
	The former is manually exported from an initial run using data/02packages.details.txt.
3: This creates data/cpan.metacurator.sqlite of size 13,737,984 bytes.
4: Delete data/02packages.details.txt since there is no point shipping it.

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
