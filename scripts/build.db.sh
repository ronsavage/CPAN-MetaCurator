#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

#scripts/drop.tables.pl
#scripts/create.tables.pl

time scripts/populate.sqlite.tables.pl
#time scripts/export.as.tree.pl

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST
