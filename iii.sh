#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# frontend to ii/iim for a single channel
# follows the tail of the out file
# and redirects input to the in file

: "${n:=$USER}"             # the user's nickname
: "${i:=$HOME/irc}"         # root irc dir
: "${s:=irc.freenode.net}"  # server
: "${c:=""}"                # channel
: "${m:=12}"                # max nick lenght
: "${w:=120}"               # max characters per mesg - fold after limit
: "${h:=20}"                # lines from history

[ "$1" != '-r' ] && exec rlwrap -a -r -S "${c:-$s}> " -pGREEN "$0" -r

infile="$i/$s/$c/in"
outfile="$i/$s/$c/out"

[ -p "$infile"  ] || exit 1
[ -e "$outfile" ] || { touch "$outfile" || exit 1; }

tail -f -n "$h" "$outfile" | while IFS= read -r mesg
do
	date="${mesg%% *}" mesg="${mesg#* }"
	time="${mesg%% *}" mesg="${mesg#* }"
	nick="${mesg%% *}" mesg="${mesg#* }"

	# strip '<nick>' to 'nick'
	nick="${nick#<}" nick="${nick%>}"

	# do not notify of server messages
	[ "$nick" != '-!-' ] && tput bel

	# handle /me ACTION messages
	case "$mesg" in ACTION*) mesg="${nick}${mesg#ACTION}" nick="*" ;; esac

	# fold lines breaking on spaces if message is greater than 'w' chars
	echo "$mesg" | fold -s -w "$w" | while IFS= read -r line; \
	do printf '\r%s %s %*.*s %s %s\n' "${date}" "${time}" "${m}" "${m}" "${nick}" "|" "${line}"
	done
done &

trap "stty '$(stty -g)'; kill -TERM 0" EXIT
stty -echonl -echo

bar="--------------------------------------------------------------------------------"
mark() { printf '%s -!- %.*s\n' "$(date +"%F %R")" "$w" "${bar}${bar}" >>"$outfile"; }

while IFS= read -r input; do
	case "$input" in
		'')
			continue
			;;
		:m)
			mark
			continue
			;;
		:x)
			mark
			break
			;;
		:q)
			break
			;;
		/wi" "*)
			input="/j nickserv info ${input#/wi}"
			;;
		/me" "*)
			input="ACTION${input#/me}"
			;;
		/names)
			input="/names $c"
			;;
		/op" "*)
			input="/j chanserv op $c ${input##* }"
			;;
		/deop" "*)
			input="/j chanserv deop $c ${input##* }"
			;;
		/bans)
			input="/j chanserv akick $c LIST"
			;;
		/ban" "*)
			input="/j chanserv akick $c ADD ${input##* } -- goodbye"
			;;
		/unban" "*)
			input="/j chanserv akick $c DEL ${input##* }"
			;;
		/t)
			input="/topic $c"
			;;
	esac
	[ -n "$input" ] && printf '%s\n' "$input"
done >"$infile"

