#!/usr/bin/env perl

my($db_path)	= 'data/cpan.metacurator.sqlite';
my($csv_path)	= '/tmp/topics.csv';

`echo ".h on\n.mode csv\nselect * from modules order by id" | sqlite3 $db_path > $csv_path`;
