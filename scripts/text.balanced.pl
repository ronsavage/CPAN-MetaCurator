#!/usr/bin/perl

use 5.36.0;

use File::Slurper 'read_text';

use Text::Balanced qw/extract_bracketed gen_extract_tagged/;

# -----------------

my($in_file_name) 			= './data/TextAnalysisAndFormatting.txt'; # A topic in Perl.Wiki containing '...<pre>...</pre>...'.
my($text)					= read_text($in_file_name);
my($matcher)				= gen_extract_tagged('<pre>', '</pre>');
my($extracted, $remainder)	= $matcher -> ($text);

print 'Using gen_extract_tagged(). ';
say $extracted ? "Extracted: $extracted." : 'No <pre>...</pre> tags found';

($extracted, $remainder)	= extract_bracketed($text, '<>');

print 'Using extract_bracketed(). ';
say $extracted ? "Extracted: $extracted." : 'No <pre>...</pre> tags found';

$text			=~ /<pre>(.*)<\/pre>/s;
my($match)		= $1;
my(@lines)		= split(/\n/, $match);
my($line_count)	= $#lines + 1;

print 'Using regexp. ';

if ($match)
{
	say "Extracted. Line count: $line_count";
}
else
{
	say 'No <pre>...</pre> tags found';
}
