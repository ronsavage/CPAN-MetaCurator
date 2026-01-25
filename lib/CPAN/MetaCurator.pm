package CPAN::MetaCurator;

use 5.36.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '1.03';

#-------------------------------------------------

1;

=pod

=head1 How to convert a Perl.Wiki.html into a jsTree

Steps (2025-01-25):
	a. cd ~/perl.modules/CPAN-MetaCurator/
	b. cp /dev/null log/development.log
	c. wget https://www.cpan.org/modules/02packages.details.txt.gz
	d. gunzip 02packages.details.txt.gz (Contains 270,458 records + 10 header lines)
	e. mv 02packages.details.txt data/
	f. Browse Perl.Wiki.html
	g. In the 'Tools' tab click 'export all'
	h. In the pop-up, click 'JSON format'
	i. cp ~/Downloads/tiddlers.json data/cpan.metacurator.tiddlers.json
	j. git commit -am"Some message"
	k. build.module.sh CPAN::MetaCurator 1.03
	l. scripts/build.db.sh (Takes 15 hours. Output: data/cpan.metacurator.sqlite. Size: 14,094,336 bytes)

Counts:
1. Count the # of topics:
	cd ~/perl.modules/CPAN-MetaCurator
	scripts/redo.sh
	Outputs: Topic count: 206. Leaf count: 4711 in http://127.0.0.1/misc/cpan.metacurator.tree.html

Note:
1: There is assumed to be just 1 item called 'See also' per topic, preferably at the start.
2: There is assumed to be just 1 item containing '<pre>...</pre> per topic. It can appear anywhere within the topic.
3: My web host and I use case-sensitive file systems.

If you wish to rebuld the database:
Note: File sizes as of 2026-01-04.
Note: The code shipped can be configured to change the home_path().
3. Run build.db.sh which uses that data to populate the modules table, which contains about 270,000 records.
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
