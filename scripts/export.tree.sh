#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

if [ "$INCLUDE_PACKAGES" == "" ]; then
	INCLUDE_METAPACKAGER = 0
else
	INCLUDE_METAPACKAGER = 1
fi

export $INCLUDE_METAPACKAGER

scripts/export.tree.pl -include_metapackager $INCLUDE_METAPACKAGER

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST
