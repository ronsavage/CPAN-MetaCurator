package CPAN::MetaCurator::Util::Export;

use 5.36.0;
use boolean;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::Util::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;

use Moo;

use File::Slurper 'read_lines';

our $VERSION = '1.07';

# -----------------------------------------------

sub export_as_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.

	$self -> logger -> info('Exporting the wiki as a JSTree');

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

			push @list, $$_{html} ? "<a href = '$$_{html}>$$_{text}</a>" : "<li id = '$$_{id}'>$$_{text}</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';
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
	$self -> logger -> info("Leaf count: $$pad{leaf_count}");

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
	my($self, $leaf_id, $pad, $topic)	= @_;
	my(@lines)							= grep{length} split(/\n/, $$topic{text});
	@lines								= map{s/\s+$//; s/^-\s//; s/:$//; $_} @lines;
	my($inside_see_also)				= false;
	my($line_id)						= $leaf_id;

	my($href, @hover);
	my($its_an_acronym, $its_a_package, $its_a_topic);
	my($item, @items);
	my($line);
	my(@see_also);

	for my $index (0 .. $#lines + 1)
	{
		$line = $lines[$index];

		next if ( (! $line) || ($line !~ /^o (.+)/) );

		$line_id++;

		$line			= $1;
		$item			= {href => '', id => $line_id, text => $line};
		$its_an_acronym	= $$topic{title} eq 'Acronyms' ? true : false;
		$its_a_package	= $$pad{package_names}{$line} ? true : false;
		$its_a_topic	= $$pad{topic_names}{$line} ? true : false;

		# Some names might be acronyms & module names & topic names.
		# Example: RSS.

		if ($its_a_package)
		{
			$$item{text} = "<a href = 'https://metacpan.org/pod/$line'>$line - $lines[$index + 1]</a>";

			push @items, $item;
		}

		if ($its_a_topic)
		{
			$$item{html}	= "#$$pad{topic_html_ids}{$line}";
			$$item{text}	= $line;

			push @items, $item;
		}

		if ($its_an_acronym)
		{
			$$item{text}	.= ' => ' . $lines[$index + 1];
			$$item{text}	= "<a href = '$lines[$index + 2]'>$$item{text}</a>";

			push @items, $item;
		}

		if ($its_a_package || $its_a_topic || $its_an_acronym)
		{
			# Ignore it here.
		}
		else
		{
			$$pad{count}{unknown}++;

			$self -> logger -> debug("Unknown: $line");
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

sub text2csv
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad) = $self -> build_pad;

	# Read 02packages.details.txt.

	my($in_file)	= File::Spec -> catfile($self -> home_path, $self -> packages_txt_path);
	my($out_file)	= File::Spec -> catfile($self -> home_path, $self -> packages_csv_path);

	$self -> logger -> debug("Reading $in_file");
	$self -> logger -> debug("Writing $out_file");

	my(@details)	= read_lines($in_file);
	my($header)		= 'name,version';
	my($count)		= 0;

	$self -> logger -> debug("Read @{[$#details + 1]} records from $in_file");

	my($record);

	for (1 .. 9)
	{
		$record = shift @details;

		$self -> logger -> debug("Discarding input. Line: $_ => $record");
	}

	open(OUT, '>encoding(UTF-8)', $out_file);
	print OUT "module,version\n";

	my(@fields);

	for (@details)
	{
		$count++;

		@fields = split(' ', $_);

		say OUT "$fields[0],$fields[1]";
	}

	close OUT;

	$self -> logger -> debug("Wrote $count records to $out_file");

} # End of text2csv.

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
