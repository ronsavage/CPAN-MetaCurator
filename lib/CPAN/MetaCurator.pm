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

Note: Development process. File sizes as of 2025-08-05.
1: Check the Note below before using the dev process.
2: Optionally, download Perl's 02packages.details.txt and store it in data/. Size: 23,868,403 bytes.
	Download using: wget https://www.cpan.org/modules/02packages.details.txt.gz
	Unpack using: gunzip 02packages.details.txt.gz
3: Run build.db.sh which uses that data to populate the modules table, which contains 268,476 records.
	Actually, the code preferentially uses data/modules.table.csv rather than 02packages.details.txt.
	The modules.table.csv file was manually exported from an initial run using data/02packages.details.txt.
	If I wish to check in new code I run redo.sh rather than build.db.sh.
4: Either way, the code creates data/cpan.metacurator.sqlite. Size: 13,737,984 bytes.
5: Delete data/02packages.details.txt since there is no point shipping it.

Note: Utilizing the code:
Download Perl.Wiki.html from http://savage.net.au/ like this...
Download and unpack the distro CPAN::MetaCurator from https://metacpan.org/.
Update Perl.Wiki.html if desired. but note that the format is very strict!
Export its data by clicking the Tools tab on the top right:
1: Choose 'export all'.
2: Choose 'JSON format' in the pop-up.
3: The file tiddlers.json will appear in your downloads directory (eg ~/Downloads/ under Debian).
4: Move tiddlers.json into the distro's data/ as cpan.metacurator.tiddlers.json to replace the copy shipped with the distro.
5: Run scripts/build.db.sh or scripts/redo.sh.
They read data/cpan.metacurator.tiddlers.json and output data/cpan.metacurator.sqlite.
Then they read data/cpan.metacurator.sqlite and output html/cpan.metacurator.tree.html.
The code shipped can be configured to change the home_path().
And it logs to log/development.log.

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
