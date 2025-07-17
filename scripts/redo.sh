#!/bin/bash

declare -x PREFIX=cpan.metacurator
mv ~/Downloads/tiddlers.json data/PREFIX.tiddlers.json
cd $HOME/perl.modules/CPAN-MetaCurator/
echo Work dir: `pwd`
cp /dev/null log/development.log;
build.module.sh CPAN::MetaCurator 1.00

scripts/drop.tables.pl
scripts/create.tables.pl
scripts/populate.sqlite.tables.pl
scripts/export.as.tree.pl

declare -x SOURCE=html/PREFIX.tree.html
declare -x DEST=$DS/misc
cp $SOURCE $DEST

echo Copied $SOURCE to $DEST. Lastly check no other tiddlers.json in ~/Downloads
dir ~/Downloads/tiddlers*
