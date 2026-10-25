#!/bin/bash

clear
cd $HOME/perl.modules/CPAN-MetaCurator/

scripts/zap.log.sh
time scripts/export.tree.pl -log_level debug -include_packages $INCLUDE_PACKAGES

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=~/savage.net.au/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

declare -x SOURCE=html/cpan.metacurator.help.html
declare -x DEST=~/savage.net.au/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

declare -x SOURCE=~/savage.net.au/misc
declare -x DEST=$DH/misc

cp -r $SOURCE $DEST
echo Copied $SOURCE to $DEST
