#!/usr/bin/env sh

spawn() { h=${h:-100} s="$1" c="$2" tmiii.sh; }

f='freenode'
o='oftc'

spawn "$f" "#musl"

case "$1" in
	-a)
		spawn "$f" "#foss-aueb"
		spawn "$f" "#thinking.gr"
		;;
	-aa)
		spawn "$f" "##posix"
		spawn "$f" "#awk"
		spawn "$f" "#forth"
		spawn "$f" "#concatenative"
		spawn "$f" "#sabotage"
		;;
	-aaa)
		spawn "$f" "#gentoo-el"
		spawn "$o" "#suckless"
		spawn "$o" "#ii"
		spawn "$f" "yocto"
		spawn "$f" "oe"
		;;
	-aaaa)
		spawn "$f" "##c"
		spawn "$f" "#cat-v"
		spawn "$f" "#bash"
		spawn "$f" "#nixos"
		spawn "$f" "#osarena"
		;;
esac
