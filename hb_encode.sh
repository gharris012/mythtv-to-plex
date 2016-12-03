#!/bin/bash

# encode.sh
#
# Copyright (c) 2013 Don Melton
#
# This version published on June 7, 2013.
#
# Re-encode video files in a format suitable for playback on Apple TV, Roku 3,
# iOS, OS X, etc.
#
# Input is assumed to be a single file readable by HandBrakeCLI and mediainfo,
# e.g. just about any .mkv, .avi, .mpg, etc. file.
#
# The script automatically calculates output video bitrate based on input. For
# Blu-ray Disc-quality input that's always 5000 Kbps. For DVD-quality input
# that's always 1800 Kbps. For other files that will vary.
#
# The script also automatically calculates video frame rates and audio channel
# configuration.
#
# If the input contains a VobSub (DVD-style) or PGS (Blu-ray Disc-style)
# subtitle, then it is burned into the video.
#
# Optional frame rate overrides and soft subtitles in .srt format are read
# from separate fixed locations in the `$frame_rates_location` and
# `$subtitles_location` variables defined below. Edit this script to redefine
# them.
#
# If your input file is named "foobar.mkv" then the optional frame rate file
# should be named "foobar.txt". And all it should contain is the frame rate
# number, e.g. "25" followed by a carriage return.
#
# If your input file is named "foobar.mkv" then the optional soft subtitle
# file should be named "foobar.srt".
#
# Output is an MP4 container with H.264 video, AAC audio and possibly AC-3
# audio if the input has more than two channels.
#
# No scaling or cropping is performed on the output. This is a good thing.
#
# The output .mp4 file and a companion .log file are written to the current
# directory.
#
# This script depends on two separate command line tools:
#
#   HandBrakeCLI    http://handbrake.fr/
#   mediainfo       http://mediainfo.sourceforge.net/
#   bc              http://gnuwin32.sourceforge.net/packages/bc.htm
#
# Make sure both are in your `$PATH` or redefine the variables below.
#
# Usage:
#
#   ./encode.sh [input file]
#

die() {
    echo "$program: $1" >&2
    exit ${2:-1}
}

readonly program="$(basename "$0")"
readonly input="$1"

output_ext="$2"

if [ ! "$input" ]; then
    die 'too few arguments'
fi

handbrake="HandBrakeCLI"
nicecmd="nice"
ionicecmd="ionice"
mediainfo="mediainfo"

if [ "$OSTYPE" == "msys" ]; then
    handbrake="HandBrakeCLI.exe"
    ionicecmd=""
else
    handbrake="HandBrakeCLI"
fi

# qsv only works on my windows/intel computer
if [ "$OSTYPE" == "msys" ]; then
    encoder_opts="--encoder qsv_h264 --encoder-preset=balanced"
else
    encoder_opts="--encoder x264 --encoder-preset=medium"
fi
encoder_opts="$encoder_opts --encoder-profile=high --encoder-level=4.0"
filter_opts="--crop 0:0:0:0"
handbrake_options="$encoder_opts $filter_opts --optimize --use-opencl --use-hwd"

width="$(mediainfo --Inform='Video;%Width%' "$input")"
height="$(mediainfo --Inform='Video;%Height%' "$input")"
frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "$input")"
interlaced="$(mediainfo --Inform='Video;%ScanType%' "$input")"

# some shows are reported as progressive even though they are interlaced
# try to determine them using resolution (there is no 1080p broadcast)
if [[ "$interlaced" == "Interlaced" || ( "$height" == "1080" && "$frame_rate" == "29.970" ) ]]; then
    # double framerate for bob
    frame_rate=$(echo "scale=3;$frame_rate*2"|bc)
    if [[ "$interlaced" == "Interlaced" ]]; then
        handbrake_options="$handbrake_options --deinterlace=bob"
    else
        handbrake_options="$handbrake_options --decomb=bob"
    fi
fi

handbrake_options="$handbrake_options --cfr --rate $frame_rate"

if (($width > 1280)) || (($height > 720)); then
    max_bitrate="4000"
elif (($width > 720)) || (($height > 576)); then
    max_bitrate="3000"
else
    max_bitrate="1800"
fi

min_bitrate="$((max_bitrate / 2))"

bitrate="$(mediainfo --Inform='Video;%BitRate%' "$input")"

if [ ! "$bitrate" ]; then
    bitrate="$(mediainfo --Inform='General;%OverallBitRate%' "$input")"
    bitrate="$(((bitrate / 10) * 9))"
fi

if [ "$bitrate" ]; then
    bitrate="$(((bitrate / 5) * 4))"
    bitrate="$((bitrate / 1000))"
    bitrate="$(((bitrate / 100) * 100))"

    if (($bitrate > $max_bitrate)); then
        bitrate="$max_bitrate"
    elif (($bitrate < $min_bitrate)); then
        bitrate="$min_bitrate"
    fi
else
    bitrate="$min_bitrate"
fi

handbrake_options="$handbrake_options --vb $bitrate"

# all-subtitles and all-audio are not available in my version
handbrake_options="$handbrake_options --subtitle 1,2,3,4"
handbrake_options="$handbrake_options --audio 1,2,3,4 --aencoder copy --audio-copy-mask aac,ac3,dts --audio-fallback av_aac"

output="$input"
outputbase="${output%\.[^.]*}"

if [ -n "$output_ext" ]; then
    outputbase="$outputbase - $output_ext"
fi

output="$outputbase.mp4"

if [ -f "$output" ] ; then
    read -p "Output file \"$output\" exists, overwite? (y/n)? " userPrompt
    echo
    if [ "n" == "$userPrompt" ] ; then
        output_idx=0
        while [ -f "$output" ] ; do
            let output_idx=output_idx+1
            output="$outputbase - $output_idx.mp4"
            if [ "$output_idx" -gt 8 ] ; then
                break
            fi
        done
    fi
fi

echo "Encoding: $input to $output" >&2
echo "$handbrake_options" >&2

time "$nicecmd" $ionicecmd "$handbrake" \
    $handbrake_options \
    --input "$input" \
    --output "$output" \
    2>&1 | tee -a "${output}.log"
