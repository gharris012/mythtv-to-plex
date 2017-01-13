#!/bin/bash

basedir="/dvr/recordings/mythtv"

if [ "$#" -eq "1" ]; then
	showname="$1"
	if [ -d "$1" ]; then
		finddir="$1"
	else
		finddir="$basedir/$1"
	fi
else
	finddir="$basedir"
fi

if [ ! -d "$finddir" ]; then
	echo "invalid directory: $finddir"
	exit 1
fi

if [ -n "$(find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf 1 -quit)" ]; then
	find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf "  %P -> %l\n"

	read -p "Remove broken links? " removePrompt
	echo

	if [ "y" == "$removePrompt" ] ; then
		find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf "  %P -> %l\n" -delete
	fi
	echo
fi

if [ -n "$(find "$finddir" -type d -empty -printf 1 -quit)" ]; then
	find "$finddir" -type d -empty -print
	read -p "Remove empty directory? " removePrompt
	echo

	if [ "y" == "$removePrompt" ] ; then
		echo " Removing Empty Directories"
		find "$finddir" -type d -empty -print -delete
	fi
	echo
fi

echo "Done"
