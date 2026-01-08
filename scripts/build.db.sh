#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/
echo Work dir: `pwd`
cp /dev/null log/development.log
git commit -am"Rebuilding the distro"
build.module.sh CPAN::MetaCurator 1.02

scripts/drop.tables.pl
scripts/create.tables.pl
time scripts/populate.sqlite.tables.pl
time scripts/export.as.tree.pl

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST
