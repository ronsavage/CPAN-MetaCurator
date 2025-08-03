package CPAN::MetaCurator::Util::Import;

use 5.40.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;
use File::Slurper 'read_lines';

use Moo;
use Mojo::JSON 'from_json';

use Text::CSV::Encoded;
use Types::Standard qw/Str/;

our $VERSION = '1.01';

# -----------------------------------------------

sub import_csv_file
{
	my($self, $csv, $path, $table_name, $col_name_1, $col_name_2) = @_;

	$self -> logger -> info("Populating the 'table_name' table with import_csv_file()");

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	my($error_message);
	my(%keys);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (@{$self -> column_names})
		{
			if (! defined $$item{$column})
			{
				$self -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if ($keys{$$item{$col_name_1} })
		{
			$error_message = "$table_name. Duplicate $table_name.$col_name_1: $keys{$$item{$col_name_1} }";

			$self -> logger -> error($error_message);

			die $error_message;
		}

		$keys{$$item{$col_name_1} } = $self -> insert_hashref
		(
			$table_name,
			{
				id			=> $count,
				$col_name_1	=> $$item{$col_name_1},
				$col_name_2	=> $$item{$col_name_2},
			}
		);

		say "Stored $count records into '$table_name'" if ($count % 10000 == 0);
	}

	close $io;

	$self -> logger -> info("Stored $count records into '$table_name'");

} # End of import_csv_file.

# -----------------------------------------------

sub import_perl_modules
{
	my($self, $path, $table_name) = @_;
	my($count)	= 0;
	my(@names)	= read_lines($path);
	my($record)	= {};

	my($id);
	my(%names);
	my(@pieces);

	$self -> logger -> info("Populating the 'table_name' table with import_perl_modules()");

	for (@names)
	{
		@pieces = split(/\s+/, $_, 3); # 3 => [0], [1], [*].

		next if (! $pieces[0]);			# Skip blank lines.
		next if ($pieces[0] =~ /:$/);	# Skip headers.

		$count++;

		$$record{name}		= $pieces[0];
		$$record{version}	= $pieces[1];
		$id					= $self -> insert_hashref($table_name, $record);

		say "Stored $count records into '$table_name'" if ($count % 10000 == 0);
	}

	$self -> logger -> info("Stored $count records into '$table_name'");

} # End of import_perl_modules.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;
	$self -> logger -> info('Populating all tables');

	my($csv) = Text::CSV::Encoded -> new
	({
		allow_whitespace	=> 1,
		encoding_in			=> 'utf-8',
		strict				=> 1,
	});

	$self -> populate_constants_table($csv);
	$self -> populate_modules_table($csv);
	$self -> populate_topics_table;

	$self -> logger -> info('Populated all tables');
	$self -> logger -> info('-' x 50);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_constants_table
{
	my($self, $csv)	= @_;
	my($path)		= File::Spec -> catfile($self -> home_path, $self -> constants_path);
	my($table_name)	= 'constants';

	$self -> get_table_column_names(true, $table_name); # Populates $self -> column_names.
	$self -> import_csv_file($csv, $path, $table_name, 'name', 'value');

}	# End of populate_constants_table.

# -----------------------------------------------

sub populate_modules_table
{
	my($self, $csv)		= @_;
	my($database_path)	= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($csv_path)		= File::Spec -> catfile($self -> home_path, $self -> modules_table_path);
	my($status)			= (-e $csv_path) ? 'Present' : 'Absent';
	my($table_name)		= 'modules';

	$self -> get_table_column_names(true, $table_name); # Populates $self -> column_names.

	if ($status eq 'Present')
	{
		#Takes hours. The next line takes 1.7s!
		#$self -> import_csv_file($csv, $path, $table_name, 'name', 'version');

		`csv2sqlite --format=csv --table $csv_path $database_path`;
	}
	else
	{
		$self -> import_perl_modules($self -> home_path, $self -> perl_modules_path, $table_name);
	}

}	# End of populate_modules_table.

# -----------------------------------------------

sub populate_topics_table
{
	my($self)		= @_;
	my($data)		= $self -> read_tiddlers_file;
	my($count)		= 1;
	my($record)		= {parent_id => 1, text => 'Root', title => 'MetaCurator'}; # Parent is self.
	my($table_name)	= 'topics';
	my($root_id)	= $self -> insert_hashref($table_name, $record);

	my($id);
	my($text, $title);

	for my $index (0 .. $#$data)
	{
		# Node keys: created modified text title.

		$text	= $$data[$index]{text};
		$title	= $$data[$index]{title};

		next if ($title =~ /GettingStarted|MainMenu/); # TiddlyWiki special cases.

		$count++;

		$self -> logger -> info("Missing text @ line: $index. title: $title"), next if (! defined $text);
		$self -> logger -> info("Missing prefix @ line: $index. title: $title"), next if ($text !~ m/^\"\"\"\no (.+)$/s);

		$$record{parent_id}	= $root_id;
		$$record{title}		= $title;
		$text				= $1 if ($text =~ m/^\"\"\"\n(.+)$/s);
		$$record{text}		= $text;
		$id					= $self -> insert_hashref($table_name, $record);

		$self -> logger -> info('AiEngines: ' . $text) if ($title eq 'AiEngines'); # Test UTF-8 chars.
	}

	$self -> logger -> info("Stored $count records into '$table_name'");

} # End of populate_topics_table;

# --------------------------------------------------

sub read_tiddlers_file
{
	my($self)		= @_;
	my($file_name)	= File::Spec -> catfile($self -> home_path, $self -> tiddlers_path);
	my($json)		= join('', read_lines($file_name, 'UTF-8') );

	return from_json $json;

} # End of read_tiddlers_file.
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
