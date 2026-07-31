#!/bin/bash

declare -x SOURCE=data/cpan.metacurator.sqlite
declare -x DEST=/tmp/topics.csv

echo ".headers on\n.mode csv\nselect id,title from topics order by title" | sqlite3 $SOURCE > $DEST
#echo ".mode csv\nselect id,title from topics order by title" | sqlite3 $SOURCE > $DEST
