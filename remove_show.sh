#!/bin/bash

basedir="/dvr/recordings/mythtv"
showname="$1"

if [ -d "$1" ]; then
	finddir="$1"
else
	finddir="$basedir/$1"
fi

if [ ! -d "$finddir" ]; then
	echo "invalid directory: $finddir"
	exit 1
fi

find "$finddir" -type l -lname '/dvr/recordings*' -exec sh -c 'echo "  $1 -> $(readlink -e "$1")"' _ "{}" \;

read -p "Remove all episodes from $1? " removePrompt
echo

if [ "y" == "$removePrompt" ] ; then

	echo " Removing broken links"
	find "$finddir" -type l ! -exec test -e {} \; -printf "  %P -> %l\n" -delete

	echo " Removing Episodes"

	# find "$finddir" -type l -lname '/dvr/recordings*' -exec sh -c 'echo "  $1 -> $(readlink -e "$1")" && ls -hoH "$1" && ls -l "$1" && rm -i $(readlink -e "$1") && rm -i "$1"' _ "{}" \;
	find "$finddir" -type l -lname '/dvr/recordings*' -exec sh -c 'echo "  $1 -> $(readlink -e "$1")" && rm $(readlink -e "$1") && rm "$1"' _ "{}" \;

	echo " Removing Empty Directories"
	find "$finddir" -type d -empty -print
	find "$finddir" -type d -empty -delete
fi
echo "Done"

