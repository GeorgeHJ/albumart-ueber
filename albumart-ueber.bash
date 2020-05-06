#!/bin/bash
# A Script to Display Album Art in a TMUX pane
# From this reddit thread: https://www.reddit.com/r/unixporn/comments/3q4y1m/openbox_music_now_with_tmux_and_album_art/
# Replacing W3M with Ueberzug
MUSIC_DIR="/home/george/Music"
filename=""
old_filename=""

#default dimensions
width=32
height=32
x=0
y=0

# shellcheck disable=SC1090
source "$(ueberzug library)"

mpd_check() {
	# wait until mpd is running
	while true; do
		sleep 1
		if mpc -q 2</dev/null; then
			break
		fi
	done
}

art_filename() {
	# use mpc to find the path of the currently playing album's artwork
	local current_file
	local current_dir
	current_file=$(mpc current -f "%file%")
	current_dir=$(dirname "$current_file")

	if [ -n "$current_file" ]; then
		filename=$(find $MUSIC_DIR/"$current_dir" -name "*[Ff]ront*[png|jpg|bmp]")
		if [ -z "$filename" ]; then
			filename=$(find $MUSIC_DIR/"$current_dir" -name "*[Cc]over*[png|jpg|bmp]")
			if [ -z "$filename" ]; then
				filename=$(find $MUSIC_DIR/"$current_dir" -name "*[Ff]older*[png|jpg|bmp]")
			fi
		fi

		if [ -z "$filename" ]; then
			filename="/home/george/Pictures/no_art.png"
		fi
	fi
}

update_art() {
	# update $old_filename and then (re)-fetch the filename for the current album cover
	old_filename=$filename
	art_filename
}

check_old() {
	# check to see if the filename has changed
	while true; do
		mpc idle player update >/dev/null
		update_art
		if [ "$old_filename" != "$filename" ]; then
			break && old_filename=$filename
		fi
	done
}

ueber_art() {
	# shellcheck disable=SC2102
	# Declare the image details, time it with the check_old function, pipe it to ImageLayer
	{
		ImageLayer::add [identifier]="album_art" [x]="$x" [y]="$y" [width]="$width" [height]="$height" [path]="$filename"
		check_old
	} | ImageLayer
}

clear_art() {
	# shellcheck disable=SC2102
	{
		ImageLayer::remove [identifier]="album_art"
	} | ImageLayer
}

finish() {
	# Cleanup steps
	clear_art
	tput cnorm # make cursor visible
	exit 0
}

main() {
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
