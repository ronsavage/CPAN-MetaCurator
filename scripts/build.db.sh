#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/
echo Work dir: `pwd`
build.module.sh CPAN::MetaCurator 1.00

scripts/drop.tables.pl
scripts/create.tables.pl
scripts/populate.sqlite.tables.pl
scripts/export.as.tree.pl

cp html/cpan.metacurator.tree.html $DS

echo Copied html/cpan.metacurator.tree.html to $DS
