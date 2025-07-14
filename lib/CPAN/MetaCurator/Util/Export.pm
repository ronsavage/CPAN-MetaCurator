package CPAN::MetaCurator::Util::Export;

use 5.40.0;
use boolean;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::Util::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub export_as_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad);

	# Get the topics' titles, which are TiddlyWiki paragraph names.

	my(%title, $topic);

	for $topic (@{$$pad{topics} })
	{
		$title{$$topic{title} } = $$topic{id};
	}

	# Populate the body.

	my(@list)	= '<ul>';
	my($root)	= shift @{$$pad{topics} };
	my($id)		= $$root{id};
	$root		= $$root{title};

	push @list, qq|<li data-jstree='{"opened": true}' id = '$id'><a href = '#'>$root</a>|;
	push @list, '<ul>';

	my(@divs);
	my($item);
	my($lines);

	for $topic (@{$$pad{topics} })
	{
		$id		= 1000 * $$topic{id};
		$lines	= $self -> format_text($pad, \%title, $$topic{text});

		push @list, qq|\t<li id = '$$topic{id}'>$$topic{title}|;
		push @list, '<ul>';

		for (@$lines)
		{
			$id++;

			$item = $$_{href} ? "<a href = '$$_{href}'>$$_{text}</a>" : $$_{text};

			push @list, "<li id = '$id'>$item</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';
	}

	push @list, '</ul>', '</li>', '</ul>';

	my($list)	= join("\n", @list);
	$body		=~ s/!list!/$list/;

	$self -> write_file($header, $body, $footer, $pad);

	return 0;

} # End of export_as_tree.

# --------------------------------------------------

sub format_text
{
	my($self, $pad, $title, $text)	= @_;
	my(@text)				= grep{length} split(/\n/, $text);
	@text					= map{s/^-\s+//; s/:$//; $_} @text;
	my($inside_see_also)	= false;
	my($module_name_re)		= qr/^([A-Z]+[a-z]{0,}|[a-z]+)/o; # A Perl module, hopefully.

	my($href);
	my(@lines);
	my(@see_also);
	my($token);

	for (0 .. $#text)
	{
		$self -> logger -> info("Starting topic: $text[$_]");

		$token = {href => '', text => ''};

		if ($text[$_] =~ /^o\s+/)
		{
			$$token{text} = substr($text[$_], 2); # Chop off 'o ' prefix.

			$self -> logger -> info("Missing text @ line $_") if (length($text[$_]) == 0);

			if ($inside_see_also)
			{
				$inside_see_also = false;
			}

			if ($$token{text} =~ /^[A-Z]+$/) # Eg: Acronyms.
			{
				$$token{text} .= " => $text[$_ + 1]";
			}
			elsif ($$token{text} =~ /^http/) # Eg: AdventPlanet.
			{
				$$token{href} = $$token{text};
			}
			elsif ($$token{text} =~ /^See also/) # Eg: ApacheStuff.
			{
				$inside_see_also = true;

				next; # Discard this line. Add it back below, with a ':'.
			}
			elsif ($_ <= $#text - 2)
			{
				if ($text[$_ + 1] =~ /^http/) # Eg: AudioVisual.
				{
					$$token{href} = $text[$_ + 1];
				}
				elsif ($$token{text} =~ $module_name_re) # Eg: builtins, Imager, GD and GD::Polyline.
				{
					$$token{text} = "<a href = 'https://metacpan.org/pod/$$token{text}'>$$token{text}: $text[$_ + 1]</a>";
				}
				else
				{
					$$token{text} .= " => $text[$_ + 1]";

					if ($text[$_ + 2] =~ /^http/) # Eg: Most entries.
					{
						$$token{href} = $text[$_ + 2];
					}
				}
			}

			push @lines, $token;
		}
		elsif ($inside_see_also)
		{
			push @see_also, $text[$_];
		}
	}

	my($count) = 0;

	my($text_is_para);

	for (@see_also)
	{
		$count++;

		if ($count == 1)
		{
			$token = {href => '', text => 'See also:'};

			push @lines, $token;
		}

		$text_is_para	= $$title{$_} ? true : false;
		$text_is_para	= true if (substr($_, 0, 2) eq '[[');
		$token			= {href => '', text => ''};

		#say "<$_> is" . ($text_is_para ? '' : ' not') . ' a para';

		if ($_ =~ /^http/)
		{
			$$token{text} .= "<a href = '$_'>$_</a>";
		}
		elsif ( ($_ =~ $module_name_re) && (! $text_is_para) ) # Eg: builtins, Imager, GD and GD::Polyline. Not ChartingAndPlotting.
		{
			$$token{text} .= "<a href = 'https://metacpan.org/pod/$_'>$_</a>";
		}
		else
		{
			$$token{html}	= "/$$pad{page_name}/#$$title{$_}";
			$$token{text}	.= ($_ =~ /^\[\[/) ? $_ : "[[$_]]";

			$self -> logger -> info("Token. html: $$token{html}. text: $$token{text}");
		}

		push @lines, $token;

		$$token{html} = '';
	}

	$self -> logger -> info("Line $_: <$lines[$_]{text}> & <$lines[$_]{href}>") for (0 .. $#lines);

	return \@lines;

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
