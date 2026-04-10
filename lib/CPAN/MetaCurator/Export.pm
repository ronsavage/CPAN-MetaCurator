package CPAN::MetaCurator::Export;

use 5.36.0;
use boolean;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;

use Moo;

use File::Slurper 'read_lines';

our %seen;

our $VERSION = '1.16';

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.

	# Populate the body.

	my(@list)	= '<ul>';
	my($root)	= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($id)		= $$pad{topic_html_ids}{$$root{title} };

	$self -> logger -> info("Entry: id: $id. title: $$root{title}");

	push @list, qq|<li data-jstree='{"opened": true}' id = '$id'><a href = '#'>$$root{title}</a>|;
	push @list, '<ul>';

	my(@divs);
	my($item);
	my($leaf_id, $lines_ref);

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("Entry: id: $$topic{id}. html_id: $$pad{topic_html_ids}{$$topic{title}}. title: $$topic{title}");

		$leaf_id	= $$pad{topic_html_ids}{$$topic{title} };
		$lines_ref	= $self -> format_text($leaf_id, $pad, $topic);

		push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>$$topic{title}|;
		push @list, '<ul>';

		for (@$lines_ref)
		{
			$$pad{count}{leaf}++;

			push @list, $$_{html} ? "<li>$$_{html}</li>" : "<li id = '$$_{id}'>$$_{text}</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';

		$self -> logger -> info($self -> visual_break);
	}

	push @list, '</ul>', '</li>', '</ul>';

	my($list)	= join("\n", @list);
	$body		=~ s/!list!/$list/;

	for $_ (keys %{$$pad{count} })
	{
		$header =~ s/!$_!/$$pad{count}{$_}/;
	}

	$self -> write_file($header, $body, $footer, $pad);
	$self -> logger -> info("$_ count: $$pad{count}{$_}") for (sort keys %{$$pad{count} });

	return 0;

} # End of export_tree.

# --------------------------------------------------

sub export_modules_table
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($database_path)		= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($modules_csv_path)	= File::Spec -> catfile($self -> home_path, $self -> output_path);

	$self -> logger -> info("Exporting modules table");
	$self -> logger -> info("Reading: $database_path");
	$self -> logger -> info("Writing: $modules_csv_path");

	my($command)				= `echo ".h on\n.mode csv\nselect * from modules" | sqlite3 $database_path > $modules_csv_path`;
	my($line_count)				= `wc -l $modules_csv_path`;
	my($module_count, $name)	= split(' ', $line_count);
	$module_count--; # Allow for header record.

	$self -> logger -> info("Output record count (excluding header): $module_count");

} # End of export_modules_table.

# --------------------------------------------------

sub format_text
{
	my($self, $leaf_id, $pad, $topic)	= @_;
	my(@lines)							= split(/\n/, $$topic{text});
	@lines								= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($line_id)						= $leaf_id;
	my($index)							= 0;

	my($button);
	my($description);
	my(@extras);
	my($href, @hover);
	my($item, @items);
	my($line);
	my(%node_type);
	my(@pre_pre);
	my(%special_case, @see_also);
	my($token);

	$special_case{pre_pre}	= false;
	$special_case{see_also}	= false;

	while ($index <= $#lines)
	{
		$line = $lines[$index];

		# Skip <pre>...</pre>.
		# Do not stockpile ATM.

		if ($line =~ /<pre>/)
		{
			$index++ while ($lines[$index] !~ /<\/pre>/);

			$index++;

			next;
		}

		$index++;

		# Handle the case of PdfStuff where the </pre> is the last line...

		last if ($index > $#lines);

		$self -> logger -> debug("Line $index: >$line<");

		next if ($line =~ /^o See also|^o builtins/); # For the moment.
		next if ($line !~ /^o (.+):?/);

		$token	= $1 || '';
		$item	= {href => '', id => ++$line_id, text => ''};

		$node_type{acronym}	= $$topic{title} eq 'Acronyms'	? true : false;
		$node_type{topic}	= $$pad{topic_names}{$token}	? true : false;
		$node_type{known}	= $$pad{packages}{$token}		? true : false;
		$node_type{unknown}	= ! ($node_type{acronym} || $node_type{known} || $node_type{topic});

		# Some names might be acronyms & module names & topic names.
		# Example: RSS.

		if ($node_type{acronym})
		{
			$$pad{count}{acronym}++;
		}
		elsif ($node_type{topic})
		{
			# These are counted in Database.build_pad().
		}
		elsif ($node_type{known})
		{
			$$pad{count}{known}++;
		}
		elsif ($node_type{unknown})
		{
			$$pad{count}{unknown}++;

			$self -> logger -> debug("Unknown: $token");
		}

		if ($$topic{title} eq 'FAQ')
		{
			$$item{html}	= '';
			$$item{text}	= $line;

			push @items, $item;
		}
		else
		{
			# Do we have a standard 3 line entry or 3+ lines? Examples are from Acronyms.
			#
			# 3 line entry:
			# o DKIM:
			# - DomainKeys Identified Mail <- $index
			# - https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail
			#
			# 3+ line entry:
			# o DMARC:
			# - Domain-based Message Authentication, Reporting, and Conformance <- $index
			# - https://en.wikipedia.org/wiki/DMARC
			# - An email authentication protocol that helps protect domain owners and recipients from email spoofing, phishing, and other email-based attacks
			# - https://datatracker.ietf.org/doc/html/draft-crocker-dmarc-bcp-03
			#
			# If the latter then stockpile lines beyond 3 & stash them in a hidden field to be popped-up on a button click.

			$button		= '';
			@extras		= ();

			while ( ($index <= $#lines) && ($lines[$index] !~ /^o/) )
			{
				push @extras, $lines[$index++];
			}

			if ($#extras < 2)
			{
				$self -> logger -> error("Token: $token. Extra: $_ >$extras[$_]<") for (0 .. $#extras);
			}

			$self -> logger -> error("Token: $token. Missing lines"), next if ($#extras < 2);
			$self -> logger -> error("Token: $token. Missing -text"), next if ($extras[0] !~ /^-/);
			$self -> logger -> error("Token: $token. Missing -link"), next if ( ($#extras < 1) || ($extras[1] !~ /^-/) );

			$description	= shift @extras;
			$href			= shift @extras;

			$self -> logger -> error("Token: $token. Missing description"),	next if (! defined($description) );
			$self -> logger -> error("Token: $token. Missing href"), 		next if (! defined($href) );

			if ($#extras >= 0)
			{
				$button = "<span>&nbsp;&nbsp;</span><button id='toggle-btn'>[TBA]</button>";

				$self -> logger -> debug("Token: $token. Extras:");
				$self -> logger -> debug("\t$_") for (@extras);
			}

			$$item{html}	= "<span><a href = '$href' target = '_blank'>$token - $description</a></span><span>.</span>$button";
			$$item{text}	= "";

			push @items, $item;
		}

		if (! $seen{$token})
		{
			$self -> insert_hashref('modules', {name => $token});

			$seen{$token} = true;
		}

=pod

	my($count) = 0;

	my($entry);
	my(@pieces);
	my($text_is_topic, $topic_id);

	for $item (@see_also)
	{
		$count++;

		if ($count == 1)
		{
			$$topic{id}++;

			push @lines, {href => '', id => $$topic{id}, text => 'See also:'};
		}

		@pieces			= split(/ - /, $$item{text});
		$pieces[0]		= $1 if ($pieces[0] =~ $topic_name_re); # Eg: [[XS]].
		$pieces[1]		= defined($pieces[1]) && (length($pieces[1]) ) ? "$pieces[0] - $pieces[1]" : $pieces[0];
		$topic_id		= $$pad{topic_names}{$pieces[0]} || 0;
		$text_is_topic	= ($topic_id > 0) ? true : false;

		if ($$item{text} =~ /^http/) # Eg: https://perldoc.perl.org/ - PerlDoc
		{
			$$item{text} = "<a href = '$pieces[0]'>$$item{text}</a>";
		}
		elsif ($text_is_topic) # Eg: GeographicStuff or [[HTTPHandling]] or CryptoStuff - re Data::Entropy
		{
			$self -> logger -> error("Missing id for topic") if ($topic_id == 0);

			$$item{text}	= "$pieces[0] (topic)";
			#$$item{text}	= "<a href = '#$topic_id'>pieces[1]</a>";
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('$topic_id');">$$item{text}</button>|;
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('#$topic_id');">$$item{text}</button>|;
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('\#$topic_id');">$$item{text}</button>|;
		}
		else # Eg: It's a module.
		{
			$$item{text} = "<a href = 'https://metacpan.org/pod/$pieces[0]'>$$item{text}</a>";
		}

		push @lines, $item;
=cut

	}

	return [@items];

} # End of format_text.

# --------------------------------------------------

sub write_file
{
	my($self, $header, $body, $footer, $pad) = @_;
	my($encoding)		= lc $$pad{encoding};
	my($output_path)	= File::Spec -> catfile($self -> home_path, $self -> output_path);

	open(my $fh, ">$encoding", $output_path);
	print $fh $header, $body, $footer;
	close $fh;

	$self -> logger -> info("Created $output_path. Encoding: $encoding");

} # End of write_file.

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
