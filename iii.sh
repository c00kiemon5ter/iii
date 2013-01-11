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
: "${p:=1}"                 # prefity - colors and special patterns

[ "$1" != '-r' ] && exec rlwrap -a -r -S "${c:-$s}> " -pGREEN "$0" -r

infile="$i/$s/$c/in"
outfile="$i/$s/$c/out"
sepr='|'

# colors
reset="$(tput sgr0)"
black="$(tput setaf 8)"
yellow="$(tput setaf 11)"
darkcyan="$(tput setaf 6)"

[ -p "$infile"  ] || exit 1
[ -e "$outfile" ] || { touch "$outfile" || exit 1; }

tail -f -n "$h" "$outfile" | while IFS= read -r line
do
	unset date time nick mesg

	date="${line%% *}" line="${line#* }"
	time="${line%% *}" line="${line#* }"
	nick="${line%% *}" line="${line#* }"

	# strip '<nick>' to 'nick'
	nick="${nick#<}" nick="${nick%>}"

	# do not notify of server messages
	[ "$nick" != '-!-' ] && tput bel

	# pretify
	if [ "$p" -ne 0 ]
	then
		unset clrdate clrnick clrsepr clrmesg

		clrdate="${darkcyan}"
		case "$line" in *"$n"*) clrdate="${yellow}" ;; esac

		clrnick="$(printf '(%d ^ %d + %d)' "${#nick}" "'$nick" "'${nick#?}")"
		clrnick="$(( clrnick % 14 + 1 ))"
		clrnick="$(tput setaf "$clrnick")"

		clrsepr="${darkcyan}"

		clrmesg="${reset}"
		[ "$nick" = '-!-' ] && clrmesg="${black}"

		[ "${line%% *}" = 'ACTION' ] && clrmesg="${clrnick}"
	fi

	# handle /me ACTION messages
	if [ "${line%% *}" = 'ACTION' ]
	then
		line="${line#ACTION}"
		line="${nick}${reset}${line}"
		nick="*"
	fi

	# fold lines breaking on spaces if message is greater than 'w' chars
	echo "$line" | fold -s -w "$w" | while IFS= read -r mesg; \
	do
		printf '\r%s%s %s %s%*.*s %s%s %s%s%s\n' \
			"${clrdate}" "${date}" "${time}"     \
			"${clrnick}" "${m}" "${m}" "${nick}" \
			"${clrsepr}" "${sepr}"               \
			"${clrmesg}" "${mesg}" "${reset}"
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

