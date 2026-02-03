package CPAN::MetaCurator::Util::Export;

use 5.36.0;
use boolean;
use constant id_scale_factor => 10000;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::Util::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;

use Moo;

our $VERSION = '1.06';

# -----------------------------------------------

sub export_as_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	$self -> logger -> info('Exporting the wiki as a JSTree');

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.

	# Populate the body.

	my(@list)	= '<ul>';
	my($root)	= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.

	$$pad{topic_count}++;

	$self -> logger -> info("Topic: $$pad{topic_count}. id: $$root{id}. title: $$root{title}");

	push @list, qq|<li data-jstree='{"opened": true}' id = '$$root{id}'><a href = '#'>$$root{title}</a>|;
	push @list, '<ul>';

	my(@divs);
	my($item);
	my($lines_ref);

	for my $topic (@{$$pad{topics} })
	{
		$$pad{topic_count}++;

		$$topic{id} = id_scale_factor * $$topic{id}; # Fake id offset for leaf.

		$self -> logger -> info("Topic: $$pad{topic_count}. id: $$topic{id}. title: $$topic{title}");

		$lines_ref = $self -> format_text($pad, $topic);

		push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$topic{id}'>$$topic{title}|;
		push @list, '<ul>';

		for (@$lines_ref)
		{
			$$pad{leaf_count}++;

			$item = $$_{href} ? "<a href = '$$_{href}' target = '_blank'>$$_{text}</a>" : $$_{text};

			push @list, "<li id = '$$_{id}'>$item</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';

	}

	push @list, '</ul>', '</li>', '</ul>';

	my($list)	= join("\n", @list);
	$body		=~ s/!list!/$list/;
	my(%data)	= (leaf_count => $$pad{leaf_count}, topic_count => $$pad{topic_count});

	for $_ (keys %data)
	{
		$header =~ s/!$_!/$data{$_}/;
	}

	$self -> write_file($header, $body, $footer, $pad);

	$self -> logger -> info("Leaf count:  $$pad{leaf_count}");
	$self -> logger -> info("Topic count: $$pad{topic_count}\n");

	return 0;

} # End of export_as_tree.

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
	my($self, $pad, $topic) = @_;
	my($target)				= 'TestingHelp';
	my(@text)				= grep{length} split(/\n/, $$topic{text});
	@text					= map{s/\s+$//; s/^-\s//; s/:$//; $_} @text;
	my($inside_see_also)	= false;
	my($topic_name_re)		= qr/\[\[(.+)\]\]/o; # A topic name, eg [[XS]].

	my($href, @hover);
	my($item);
	my(@lines);
	my(@see_also);

	for (0 .. $#text)
	{
		$$topic{id}++;

		$item = {href => '', id => $$topic{id}, text => ''};

		if ($text[$_] =~ /^o\s+/)
		{
			$$item{text} = substr($text[$_], 2); # Chop off 'o ' prefix.

			$self -> logger -> debug("a. Topic is $$item{text}");
			$self -> logger -> error("Missing text @ line # $_") if (length($text[$_]) == 0);

			if ($inside_see_also)
			{
				$self -> logger -> debug("b. Topic is $$item{text}");

				$inside_see_also = false;
			}

			if ($$item{text} =~ /^[A-Z]+$/) # Eg: Any acronym.
			{
				$$item{text} .= " => $text[$_ + 1]";

				$self -> logger -> debug("c. Topic is $$item{text}");
			}
			elsif ($$item{text} =~ /^http/) # Eg: AdventPlanet.
			{
				$$item{href} = $$item{text};

				$self -> logger -> debug("d. Topic is $$item{text}");
			}
			elsif ($$item{text} =~ /^See also/) # Eg: ABeCeDarian.
			{
				$inside_see_also = true;

				next; # Discard this line. Add it back below, with a ':'.
			}
			elsif ($_ <= $#text - 2)
			{
				if ($text[$_ + 1] =~ /^http/) # Eg: AudioVisual.
				{
					$$item{href} = $text[$_ + 1];

					$self -> logger -> debug("e. Topic is $$item{text}");
				}
				elsif ($$pad{module_names}{$$item{text} }) # Eg: builtins, GD, GD::Polyline.
				{
					$$item{text} = "<a href = 'https://metacpan.org/pod/$$item{text}'>$$item{text} - $text[$_ + 1]</a>";

					$self -> logger -> debug("f. Topic is $$item{text}");
				}
				else
				{
					$$item{text} .= " => $text[$_ + 1]";

					if ($text[$_ + 2] =~ /^http/) # Eg: Most entries.
					{
						$$item{href} = $text[$_ + 2];
					}

					$self -> logger -> debug("g. Topic is $$item{text}");
				}
			}
			else
			{
				push @hover, $text[$_];
			}

			push @lines, $item;
		}
		elsif ($inside_see_also)
		{
			$$item{text} = $text[$_];

			push @see_also, $item;

			$self -> logger -> debug("h. Topic is $$item{text}");
		}
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
	}

=cut

	return [@lines];

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
