#!/usr/bin/env bash

# Initial arguments: header-text height width list-height
declare -a args=("Make your selection(s)" 20 70 20)

# Add each line to the checklist, using the first column as the tag
while read -r tag item; do
    # tag item status
        args+=("$tag $item" "$item" off)
	done < list.txt

	# And display the dialog and capture the output
	tmpfile=$(mktemp)
	dialog --separate-output --checklist "${args[@]}" 2>"$tmpfile"
	readarray -t selected <"$tmpfile"
	rm -f -- "$tmpfile"

	# And show the user what they picked
	printf "Your selections: "
	printf "%s " "${selected[@]}"
	printf "\n"

