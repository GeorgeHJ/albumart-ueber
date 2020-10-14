#!/bin/bash
# A Script to Display Album Art in a TMUX pane
music_dir="$HOME/Music"

#default dimensions
width=32
height=32
x=0
y=0

# size down for smaller screens
typeset -i hsize
# we only need the horizontal size here
hsize=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -f1 -dx)
if [[ hsize -lt 1920 ]]; then
	width=22
	height=22
fi

# shellcheck disable=SC1090
source "$(ueberzug library)"

main() {
	tput civis # hide the cursor
	trap finish 2
	# Main Loop
	while true; do
		tmux_client_check
		mpd_check
		update_art
		clear
		ueber_art
	done 2>/dev/null
}

rm_tmpimgfiles() {
	find /tmp -name "tmp.*.jpg" -delete 2>/dev/null
}

finish() {
	# Cleanup steps
	ueber_clear
	tput cnorm # make cursor visible
	rm_tmpimgfiles
	exit 0
}

tmux_client_check() {
	# If in a tmux session, make sure there is a client before moving on
	if [ "$TERM" == "tmux-256color" ]; then
		until tmux list-clients -t "$(tmux display -p '#{session_name}')" | grep -q pts; do
			sleep 1
		done
	fi
}

mpd_check() {
	# wait until mpd is running
	while true; do
		if mpc -q 2</dev/null; then
			break
		fi
		sleep 1
	done
}

update_art() {
	# update $old_filename and then (re)-fetch the filename for the current album cover
	old_filename=$filename
	art_filename
}

art_filename() {
	# use mpc to find the path of the currently playing album's artwork
	local current_file
	local current_dir
	local tmpimgfile
	local tmpimgfile_old
	current_file=$(mpc current -f "%file%")
	current_dir=$(dirname "$current_file")

	if [ -n "$current_file" ]; then
		# Try finding artwork in the album directory
		filename=$(find "$music_dir"/"$current_dir" -name "*[Ff]ront*[png|jpg|bmp]" | head -1)
		if [ -z "$filename" ]; then
			filename=$(find "$music_dir"/"$current_dir" -name "*[Cc]over*[png|jpg|bmp]" | head -1)
			if [ -z "$filename" ]; then
				filename=$(find "$music_dir"/"$current_dir" -name "*[Ff]older*[png|jpg|bmp]" | head -1)
			fi
		fi

		# Otherwise, try to extract artwork from the music file
		if [ -z "$filename" ]; then
			tmpimgfile=$(mktemp --suffix=.jpg)
			ffmpeg -i "$music_dir"/"$current_file" "$tmpimgfile" -y
			if ! cmp -s "$filename" "$tmpimgfile"; then
				filename=$tmpimgfile
			fi

			find /tmp -name "tmp.*.jpg" 2>/dev/null | grep -v "$filename"| xargs -r rm
		fi

		# Finally, if no art can be found then fallback to a placeholder image
		if [ -z "$filename" ]  || [ ! -s "$filename" ]; then
			filename="$HOME/Pictures/no_art.png"
		fi
	fi
}

ueber_art() {
	# shellcheck disable=SC2102
	# Declare the image details, time it with the check_old function, pipe it to ImageLayer
	{
		ImageLayer::add [identifier]="album_art" [x]="$x" [y]="$y" [width]="$width" [height]="$height" [path]="$filename"
		check_old
	} | ImageLayer
}

check_old() {
	# check to see if the file contents has changed
	while true; do
		mpc idle player update >/dev/null
		update_art
		if ! cmp -s "$old_filename" "$filename"; then
			break && old_filename=$filename
		fi
	done
}

ueber_clear() {
	# shellcheck disable=SC2102
	{
		ImageLayer::remove [identifier]="album_art"
	} | ImageLayer
}
main
