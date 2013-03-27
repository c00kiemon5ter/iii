#!/usr/bin/env sh

spawn() { h=${h:-20} s="$1" c="#$2" tmiii.sh; }

f='freenode'
o='oftc'

spawn "$f" "#c"
spawn "$f" "foss-aueb"
spawn "$f" "musl"

case "$1" in
	'-s') # shell
		spawn "$f" "bash"
		spawn "$f" "awk"
		;;
	'-x') # xlib and xcb
		spawn "$f" "xcb"
		;;
	'-c') # C and STD
		spawn "$f" "#c"
		spawn "$f" "musl"
		spawn "$f" "#posix"
		;;
	'-f') # factor forth and awesomeness
		spawn "$f" "forth"
		spawn "$f" "concatenative"
		;;
	'-o') # oftc -- suckless.org
		#spawn "$f" "cat-v"
		spawn "$o" "suckless"
		spawn "$o" "ii"
		;;
	'-p') # programming and algos
		spawn "$f" "#programming"
		spawn "$f" "#algorithms"
		;;
	'-v') # version control
		spawn "$f" "git"
		spawn "$f" "github"
		;;
	'-d') # distributions
		spawn "$f" "sabotage"
		spawn "$f" "#linux"
		spawn "$f" "crux"
		spawn "$f" "nixos"
		;;
	'-g') # greeks
		spawn "$f" "foss-aueb"
		spawn "$f" "gentoo-el"
		spawn "$f" "osarena"
		;;
	'-e') # embeded
		spawn "$f" "yocto"
		spawn "$f" "oe"
		spawn "$f" "edev"
		spawn "$f" "elinux"
		;;
esac
