package CPAN::MetaCurator::Export;

use boolean;
use feature 'say';
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Slurper qw/read_lines write_text/;

use File::Spec;

use HTML::Escape 'escape_html';

use Moo;

use Switch::Declare;		# For switch.
use Syntax::Keyword::Match;	# For match.

use Tree::DAG_Node;

use Types::Standard qw/Str/;

has dag_nodetree_path =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has jstree_html_path =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

our $leaf_id;
our %seen;

our $VERSION = '1.27';

# --------------------------------------------------

sub build_dag_tree
{
	my($self, $daughter, $pad, $topic) = @_;
	my(@lines)	= split(/\n/, $$topic{text});
	@lines		= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($index)	= -1;

	my(@components);
	my(%inside, $item);
	my($leaf, $line, $line_count);
	my($module);
	my(%node_type);
	my(@pre_pre);
	my($see_also_root);
	my($text, $token, $type);

	$inside{pre_pre}	= false;
	$inside{see_also}	= false;

	while ($index < $#lines)
	{
		$index++;

		$item	= {href => '', id => 0, text => ''};
		$line	= $lines[$index];
		$token	= ($line =~ /^o (.+)/) ? $1 : '';

		$self -> logger -> debug("Processing line $index: <$line>. token: $token");

		# $token ne '':
		# a. See also
		# b. An acronym
		# Otherwise:
		# c. A description
		# d. A href
		# e. <pre>
		# f. </pre>

		if ($token eq 'See also')
		{
			$inside{see_also}	= true;
			$see_also_root		= Tree::DAG_Node -> new({name => 'See also', attributes => {id => ++$leaf_id} });

			$daughter -> add_daughter($see_also_root);
		}
		elsif ($token)
		{
			$inside{see_also}	= false;
			$line_count			= 0;
			$module				= $token;

			if (! $seen{$module})
			{
				$seen{$module} = $self -> insert_hashref('modules', {name => $module});

				$self -> gather_statistics(\%node_type, $pad, $module, $topic);
			}
		}
		elsif ($line =~ /<pre>/)
		{
			# Fix me. What happens if there are 2 sets of <pre>...</pre> within 1 topic?

			$inside{pre_pre} = true;
		}
		elsif ($line =~ m|</pre>|)
		{
			$inside{pre_pre} = false;
		}
		elsif ($inside{pre_pre})
		{
		}
		else
		{
			$line_count++;

			$token = ($line =~ /^- (.+)/) ? $1 : '';

			if ($inside{see_also})
			{
				# Fix me. References to topics can be forward references.

				@components	= split(' - ', $token);
				$text		= ($#components < 1) ? $components[0] : $components[1];
				$type		= switch ($components[0])
				{
					case /^\[?\[?[A-Za-z]+\d?\d?\]?\]?$/	{'topic'}
					case /^http/							{'uri'}
					default									{'text'}
				};

				match ($type : eq)
				{
					case('topic')	{
										$$item{text} = ($components[0] =~ /^\[?\[?([A-Za-z]+\d?\d?)\]?\]?$/) ? $1 : $components[0];
										$$item{text} = "[Topic] <button class='btn btn-info'>$$item{text}</button>"
									}
					case('uri')		{$$item{text} = "<a href = '" . escape_html($components[0]) . "' target = '_blank'>$text</a>"}
					case('text')	{$$item{text} = $token}
				}

				$leaf = Tree::DAG_Node -> new({name => $$item{text}, attributes => {id => ++$leaf_id} });

				$see_also_root -> add_daughter($leaf);
			}
			elsif ($line_count == 1)
			{
			}
			elsif ($line_count == 2)
			{
				$leaf = Tree::DAG_Node -> new({name => $module, attributes => {id => ++$leaf_id} });

				$daughter -> add_daughter($leaf);
			}
		}
	}

} # End of build_dag_tree.

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	$$pad{jstree_html_path}		= $self -> jstree_html_path;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.
	my($origin)					= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	$leaf_id					= 0;
	my($root)					= Tree::DAG_Node -> new({name => $$origin{title}, attributes => {id => $leaf_id} });

	$self -> logger -> info($self -> visual_break);
	$self -> logger -> info("Topic: id: $leaf_id. title: $$origin{title}");

	# Phase 1: Build the DAG_Node tree.

	my($daughter);

	for my $topic (@{$$pad{topics} })
	{
		$daughter = Tree::DAG_Node -> new({name => $$topic{title}, attributes => {id => ++$leaf_id} });

		$root -> add_daughter($daughter);

		$self -> build_dag_tree($daughter, $pad, $topic);
	}

	# Phase 2: Save the DAG_Node tree to disk.

	if ($self -> dag_nodetree_path)
	{
		write_text($self -> dag_nodetree_path, join("\n", @{$root -> tree2string}) . "\n");
	}

	# Phase 3: Scan the DAG_Node tree to get the topic ids.

	my($attributes);
	my($id);
	my($name);
	my(%topic_id_map);

	$root -> walk_down
	({
		callbackback => sub
		{
			my($node, $options)	= @_;
			$attributes			= $node -> attributes;
			$name       		= $node -> name;

			if ($$options{_depth} == 1) # Topics.
			{
				$topic_id_map{$name} = $$attributes{id};
			}

		}, # End of callbackback.
		_depth => 0,
	});

	# Phase 4; Build the JS Tree.
	# New style.

	$attributes	= $root -> attributes;
	$name      	= $root -> name;

	my(@list);
	my($previous_depth);

	push @list, '<ul>';
	push @list, qq|<li data-jstree='{"opened": true}' id = '$$attributes{id}'><a href = '#'>$name</a>|;
	push @list, '<ul>';

	$root -> walk_down
	({
		callbackback => sub
		{
			my($node, $options)	= @_;
			$attributes			= $node -> attributes;
			$name       		= $node -> name;

			if ($$options{_depth} == 0) # Root.
			{
			}
			elsif ($$options{_depth} == 1) # Topics.
			{
				push '</ul>' if ($previous_depth == 2);
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$attributes{id}'>$name</li>|;
				push '<ul>';
			}
			elsif ($$options{_depth} == 2) # Modules || See also.
			{
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$attributes{id}'>$name</li>|;
			}

			$previous_depth = $$options{_depth};

		}, # End of callbackback.
		_depth => 0,
	});

	push @list, '</ul>', '</li>', '</ul>';

	# Old style.
=pod

	my($item, $items_ref);
	my($see_also_ref);

	push @list, '<ul>';
	push @list, qq|<li data-jstree='{"opened": true}' id = '$leaf_id'><a href = '#'>$$origin{title}</a>|;
	push @list, '<ul>';

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("Topic: id: $$topic{id}. html_id: $$pad{topic_names}{$$topic{title}}. title: $$topic{title}");

		($items_ref, $see_also_ref) = $self -> parse_topic($pad, $topic);

		$self -> logger -> info("parse_topic() returned: $#$items_ref, $#$see_also_ref");

		++$leaf_id;

		push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>$$topic{title}|;
		push @list, '<ul>';

		for $item (@$items_ref)
		{
			++$leaf_id;
			$$pad{count}{leaf}++;

			if ($$item{text} eq 'See also')
			{
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>See also|;
				push @list, "\t<ul>";
				push @list, qq|\t\t<li>$$_{text}</li>| for (@$see_also_ref);
				push @list, "\t</ul>";
				push @list, "\t</li>";
			}
			else
			{
				push @list, $$item{html} ? "<li>$$item{html}</li>" : "<li id = '$$item{id}'>$$item{text}</li>";
			}
		}

		push @list, '</ul>';
		push @list, '</li>';

		$self -> logger -> info($self -> visual_break);
	}

	push @list, '</ul>', '</li>', '</ul>';
=cut

	# Phase 5: Build the web page.
	# And save it to html/cpan.metacurator.tree.html

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
# Some names might be acronyms & module names & topic names.
# Example: RSS.

sub gather_statistics
{
	my($self, $node_type, $pad, $token, $topic) = @_;

	$$node_type{acronym}	= $$topic{title} eq 'Acronyms'	? true : false;
	$$node_type{topic}		= $$pad{topic_names}{$token}	? true : false;
	$$node_type{known}		= $$pad{module_names}{$token}	? true : false;
	$$node_type{unknown}	= ! ($$node_type{acronym} || $$node_type{known} || $$node_type{topic});

	$$pad{count}{acronym}++	if ($$node_type{acronym});
	$$pad{count}{known}++	if ($$node_type{known});
	$$pad{count}{unknown}++	if ($$node_type{unknown} && ($token ne 'See also') );

} # End of gather_statistics;

# --------------------------------------------------

sub parse_topic
{
	my($self, $pad, $topic) = @_;
	my(@lines)	= split(/\n/, $$topic{text});
	@lines		= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($index)	= -1;

	$self -> logger -> debug("Topic: $$topic{title}. Line count: $#lines");

	my(@components);
	my($description);
	my(@extras);
	my($href);
	my(%inside, $item, @items);
	my($line, $line_count);
	my($module, $module_leaf);
	my(%node_type);
	my(@pre_pre);
	my(@see_also);
	my($text, $token, $type);

	$inside{pre_pre}	= false;
	$inside{see_also}	= false;

	while ($index < $#lines)
	{
		$index++;

		$item	= {href => '', id => ++$leaf_id, text => ''};
		$line	= $lines[$index];
		$token	= ($line =~ /^o (.+)/) ? $1 : '';

		$self -> logger -> debug("Processing line $index: <$line>. token: $token");

		# $token ne '':
		# a. See also
		# b. An acronym
		# Otherwise:
		# c. A description
		# d. A href
		# e. <pre>
		# f. </pre>

		if ($token eq 'See also')
		{
			$inside{see_also}	= true;
			$$item{text}		= 'See also';

			push @items, $item;
		}
		elsif ($token)
		{
			$description		= '';
			$inside{see_also}	= false;
			$line_count			= 0;
			$module				= $token;

			if (! $seen{$module})
			{
				$seen{$module} = $self -> insert_hashref('modules', {name => $module});

				$self -> gather_statistics(\%node_type, $pad, $module, $topic);
			}
		}
		elsif ($line =~ /<pre>/)
		{
			# Fix me. What happens if there are 2 sets of <pre>...</pre> within 1 topic?

			$inside{pre_pre} = true;
		}
		elsif ($line =~ m|</pre>|)
		{
			$inside{pre_pre} = false;
		}
		elsif ($inside{pre_pre})
		{
			$$item{html}	= '';
			$$item{text}	= $line;

			push @pre_pre, $item;
		}
		else
		{
			$line_count++;

			$token = ($line =~ /^- (.+)/) ? $1 : '';

			if ($inside{see_also})
			{
				# Fix me. References to topics can be forward references.

				@components	= split(' - ', $token);
				$text		= ($#components < 1) ? $components[0] : $components[1];
				$type		= switch ($components[0])
				{
					case /^\[?\[?[A-Za-z]+\d?\d?\]?\]?$/	{'topic'}
					case /^http/							{'uri'}
					default									{'text'}
				};

				match ($type : eq)
				{
					case('topic')	{
										$$item{text} = ($components[0] =~ /^\[?\[?([A-Za-z]+\d?\d?)\]?\]?$/) ? $1 : $components[0];
										$$item{text} = "[Topic] <button class='btn btn-info'>$$item{text}</button>"
									}
					case('uri')		{$$item{text} = "<a href = '" . escape_html($components[0]) . "' target = '_blank'>$text</a>"}
					case('text')	{$$item{text} = $token}
				}

				push@see_also, $item;
			}
			elsif ($line_count == 1)
			{
				$description = $token;
			}
			elsif ($line_count == 2)
			{
				$href			= $token;
				$$item{html}	= "<a href = '" . escape_html($href) . "' target = '_blank'>$module - $description</a>";
				$$item{text}	= '';

				push @items, $item;
			}
			else
			{
				push @extras, $token,
			}
		}
	}

	return ([@items], [@see_also]);

} # End of parse_topic.

# --------------------------------------------------

sub write_file
{
	my($self, $header, $body, $footer, $pad) = @_;
	my($output_path) = File::Spec -> catfile($self -> home_path, $self -> jstree_html_path);

	# $$pad{encoding} has a ':' prefix, & the value is from the constants table, which is from
	# /home/ron/perl.modules/CPAN-MetaCurator/data/cpan.metacurator.constants.csv.

	open(my $fh, ">$$pad{encoding}", $output_path);
	print $fh $header, $body, $footer;
	close $fh;

	$self -> logger -> info("Created $output_path. Encoding: $$pad{encoding}");

} # End of write_file.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Test data

There is a mechanism to restrict processing to a tiny number of topics.

To this end there is an option called test_topics_path, which takes a file name.
If this file is present it is read, & each line in it is assumed to be a topic name.

Topics listed are wanted, & so the program skips processing any other topics.

There is a special case. If the file is present but empty, or absent, all topics are deemed
to appear in the file & hence are processed.

Default: /tmp/test.topics.txt.

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
