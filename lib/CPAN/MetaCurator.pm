package CPAN::MetaCurator;

our $VERSION = '1.33';

#-------------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaCurator - Manage the cpan.metacurator.sqlite database

=head1 How to convert a Perl.Wiki.html into a jsTree

Note: My web host and I use case-sensitive file systems.

=head2 Rebuild Perl Wiki Tree

=over
=item 'Run' here means run from the bash command line
=item Run: cd ~/backup
=item Run: wget https://www.cpan.org/modules/02packages.details.txt.gz
=item Run: gunzip 02packages.details.txt.gz
=item Run: cp 02packages.details.txt /tmp
=item Run: cd ~/perl.modules/CPAN-MetaCurator
=item Next, set INCLUDE_PACKAGES thus:
=item If you have /tmp/cpan.metapackager.sqlite available use INCLUDE_PACKAGES=1 or 0 (default) otherwise
=item Run: INCLUDE_PACKAGES=1
=item Run: echo $INCLUDE_PACKAGES
=item Run: export INCLUDE_PACKAGES
=item Run: scripts/build.db.sh - to import tiddlers.json file into database data/cpan.metacurator.sqlite
=item Run: scripts/export.tree.sh - to export CPAN::MetaCurator database to html/cpan.metacurator.tree.html
=item Run: git commit -am"Recreate html/cpan.metacurator.tree.html"
=item Run: git push
=back

=head2 Patch ~/savage.net.au/index.html

=over
=item Check if CSS.and.JS.Wiki, Mojo.Wiki etc need to be uploaded
=item In particular, check whether or not the version date is real and not 'Unreleased'
=item cd ~/perl.modules/Local-Website
=item Edit Local::Website's data/patches.csv
=item Run: scripts/parse.index.sh - to patch ~/savage.net.au/index.html
=item Edit index.html re any other additions, eg a News Flash
=item Run: bu5.sh savage.net.au
=item Run: bu5.sh perl.modules
=back

=head2 Upload wiki & tree

=over
=item Upload Perl.Wiki.html, cpan.metacurator.tree.html to savage.net.au/misc
=item Upload index.html
=item Log in to blogs.perl.org
=item Post details of the uploads
=item Wait ... Check how it appears on blogs.perl.org. Takes about 1 min
=back

=head2 Upload disto(s) to PAUSE

=over
=item Upload CPAN::MetaCurator to PAUSE
=back

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
