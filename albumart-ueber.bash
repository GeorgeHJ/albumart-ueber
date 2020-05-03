#!/bin/bash
# A Script to Display Album Art in a TMUX pane
# From this reddit thread: https://www.reddit.com/r/unixporn/comments/3q4y1m/openbox_music_now_with_tmux_and_album_art/
# Replacing W3M with Ueberzug
MPC="mpc"
MUSIC_DIR="/home/george/Music"
filename=""
old_filename=""

#default dimensions
width=32
height=32
x=0
y=0

source "`ueberzug library`"

function mpd_check(){
	# wait until mpd is running
	while true;
	do
		sleep 1
		if mpc -q 2</dev/null;
		then
			break
		fi
	done
}

function art_filename(){
	# use mpc to find the path of the currently playing album's artwork
	local CURRENT_FILE
	local CURRENT_DIR
	CURRENT_FILE=$($MPC current -f "%file%")
	CURRENT_DIR=$(dirname "$CURRENT_FILE")

	if [[ -n $CURRENT_FILE ]]; then
		filename=$(find $MUSIC_DIR/"$CURRENT_DIR" -name "*[Ff]ront*[png|jpg|bmp]")
		if [[ -z $filename ]]; then
			filename=$(find $MUSIC_DIR/"$CURRENT_DIR" -name "*[Cc]over*[png|jpg|bmp]")
			if [[ -z $filename ]]; then
				filename=$(find $MUSIC_DIR/"$CURRENT_DIR" -name "*[Ff]older*[png|jpg|bmp]")
			fi
		fi

		if [[ -z $filename ]]; then
			filename="/home/george/Pictures/no_art.png"
		fi
	fi
}

function update_art() {
	# update $old_filename and then (re)-fetch the filename for the current album cover
	old_filename=$filename
	art_filename
}

function check_old(){
	# check to see if the filename has changed
	while true;
	do
		mpc idle player update >/dev/null
		update_art
		if [ "$old_filename" != "$filename" ]
		then
			break && old_filename=$filename
		fi
	done
}

function ueber_art(){
	# Declare the image details, time it with the check_old function, pipe it to ImageLayer
	{	ImageLayer::add [identifier]="album_art" [x]="$x" [y]="$y" [width]="$width" [height]="$height" [path]="$filename"
		check_old
	} | ImageLayer
}

function clear_art(){
	{	ImageLayer::remove [identifier]="album_art"
	} | ImageLayer
}

function finish() {
	# Cleanup steps
	clear_art
	tput cnorm # make cursor visible
	exit 0
}

function main(){
	tput civis # hide the cursor
	trap finish 2
	# Main Loop
	while true; do
		mpd_check
		update_art
		clear
		ueber_art
	done 2>/dev/null
}
main
