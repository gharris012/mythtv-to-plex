#!/bin/bash

basedir="/dvr/recordings/mythtv"
basetargetdir="/dvr/media"
showname="$1"
targetdir="/dvr/mythtv"
showtype="tvshow"

if [ -d "$1" ]; then
    finddir="$1"
else
    finddir="$basedir/$1"
fi

if [ "$#" -eq "2" ]; then
    if [ -d "$2" ]; then
        targetdir="$2"
    else
        targetdir="$basetargetdir/$2"
        if [ "$2" == "movies" ]; then
            showtype="movie"
        fi
    fi
fi

if [ ! -d "$targetdir" ]; then
    echo "invalid target directory: $targetdir"
    exit 1
fi

if [ ! -d "$finddir" ]; then
    echo "invalid source directory: $finddir"
    exit 1
fi

echo "Migrating '$showname' from '$basedir' to '$targetdir' as $showtype"

if [ -n "$(find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf 1 -quit)" ] ; then
    echo
    echo "Broken Links:"
    find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf "  (%y) %P -> %l\n" | sort

    read -p "Clean up broken links? " userPrompt
    echo

    if [ "y" == "$userPrompt" ] ; then
        echo " Removing broken links"
        find "$finddir" -type l ! -lname "*archive/*" ! -exec test -e {} \; -printf "  %P -> %l\n" -delete
    else
        echo "skipping"
    fi
fi

if [ "$showtype" == "movie" ]; then
    if [ -n "$(find "$finddir" -type l -printf 1 -quit)" ] ; then
        find "$finddir" -type l -name "*.mpg" -o -name "*.ts" | while read line; do
            echo
            orig_fullname="$line"
            fname=$(basename "$line")
            fext="${fname##*.}"
            fbase="${fname%.*}"

            newname="$fname"
            echo "Processing file '$line'"

            read -e -i "$fbase" -p "Rename $fbase (.${fext}) (enter to keep name and continue, n to skip)? " userPrompt < /dev/tty
            if [ "n" == "$userPrompt" ]; then
                echo " skipping"
            else
                if [ -n "$userPrompt" ] ; then
                    echo " renaming $fname to ${userPrompt}.${fext}"
                    newname="${userPrompt}.${fext}"
                fi
                sudo /usr/local/bin/rsync -rLtvh --progress "$orig_fullname" --remove-source-files "$targetdir/$newname"
                echo -e '\a'
                sudo chown plex.plex -R "$targetdir"
            fi
        done
    fi
elif [ "$showtype" == "tvshow" ]; then

    if [ -n "$(find "$finddir" -type l -wholename "$finddir/Season ??/*" -printf 1 -quit)" ] ; then
        echo
        echo "Episodes to move:"
        find "$finddir" -type l -wholename "$finddir/Season ??/*" ! -name "*00e *" ! -name "* s00e*" -printf "  %P -> %l\n" | sort

        read -p "Migrate listed episodes from $1? " userPrompt
        echo

        if [ "y" == "$userPrompt" ] ; then

            echo " Copying episodes"
            sudo /usr/local/bin/rsync -rLtvh --progress --remove-source-files --exclude="Season/" --exclude="Season 00" --exclude="*00e *" --exclude="* s00e*" "$finddir"  "$targetdir"
            echo -e '\a'
            sudo chown plex.plex -R "$targetdir"
        else
            echo "skipping"
        fi

    else
        echo "No episodes to move, skipping."
    fi
else
    echo "invalid show type"
fi

if [ -n "$(find "$finddir" -type d -empty -printf 1 -quit)" ] ; then
    echo
    echo " Removing empty directories"
    find "$finddir" -type d -empty -print -delete
fi

if [ -d "$finddir" ] && [ -n "$(find "$finddir" -printf 1 -quit)" ] ; then
    echo
    echo "Remaining:"
    find "$finddir" -printf "  (%y) %P -> %l\n" | sort

    read -p "Clean up remaining (y/n/i)? " userPrompt
    echo
    if [ "y" == "$userPrompt" ] ; then
        find "$finddir" -type l -exec sh -c 'echo "  $1 -> $(readlink -e "$1")" ; [ -f "$(readlink -e "$1")" ] && rm $(readlink -e "$1") ; rm "$1"' _ "{}" \;
        find "$finddir" -type f -exec sh -c 'echo "  $1" && rm "$1"' _ "{}" \;
    elif [ "i" == "$userPrompt" ] ; then
        find "$finddir" -type l -exec sh -c 'echo "  $1 -> $(readlink -e "$1")" ; [ -f "$(readlink -e "$1")" ] && rm -i $(readlink -e "$1") ; rm -i "$1"' _ "{}" \;
        find "$finddir" -type f -exec sh -c 'echo "  $1" && rm -i "$1"' _ "{}" \;
    else
        echo "skipping"
    fi
fi

if [ -d "$finddir" ] && [ -n "$(find "$finddir" -type d -empty -printf 1 -quit)" ] ; then
    echo
    echo " Removing empty directories"
    find "$finddir" -type d -empty -print -delete
fi


if [ ! -d "$finddir" ] ; then
    echo
    echo "Success!"
else
    if [ -n "$(find "$finddir" -printf 1 -quit)" ] ; then
        echo
        echo "Still Remaining:"
        find "$finddir" -printf "  (%y) %P -> %l\n" | sort
    fi
fi

echo
echo "Done"
echo -e '\a'
