package CPAN::MetaCurator;

use 5.36.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '1.05';

#-------------------------------------------------

1;

=pod

=head1 How to convert a Perl.Wiki.html into a jsTree

Note: My web host and I use case-sensitive file systems.

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

Now create data/cpan.metacurator.sqlite. Size: 14,094,336 bytes as at 2026-02-02.
	Slow:
	l. scripts/build.db.sh --include_packages 1 (Takes 15 hours)
	Quick:
	m. scripts/build.db.sh (Takes 1 second);

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
