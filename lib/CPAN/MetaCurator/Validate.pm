package CPAN::MetaCurator::Validate;

use boolean;
use feature 'say';
use parent 'CPAN::MetaCurator::Export';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';
use File::Spec;

our $VERSION = '1.29';

# -----------------------------------------------

sub validate
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)	= $self -> build_pad;
	my($root)	= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($id)		= $$pad{topic_html_ids}{$$root{title} };

	$self -> logger -> info($self -> visual_break);
	$self -> logger -> info("Topic: id: $id. html_id: $$pad{topic_html_ids}{$$root{title}}. title: $$root{title}");
	$self -> logger -> info($self -> visual_break);

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("Topic: id: $$topic{id}. html_id: $$pad{topic_html_ids}{$$topic{title}}. title: $$topic{title}");
		$self -> parse_topic($pad, $topic);
		$self -> logger -> info($self -> visual_break);
	}

	return 0;

} # End of validate.

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

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
