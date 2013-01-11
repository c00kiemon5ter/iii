#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# frontend to ii/iim for a single channel
# follows the tail of the out file
# and redirects input to the in file

: "${u:=$USER}"             # the user's nickname
: "${i:=$HOME/irc}"         # root irc dir
: "${s:=irc.freenode.net}"  # server
: "${c:=""}"                # channel
: "${m:=12}"                # max nick lenght
: "${h:=20}"                # lines from history
: "${p:=1}"                 # pretify - colors and stuff
: "${l:=3}"                 # highlight color
: "${f:=120}"               # max characters per mesg - fold after limit

[ "$1" != '-r' ] && exec rlwrap -a -s 0 -r -b "(){}[],+=^#;|&%" -S "${c:-$s}> " -pgreen "$0" -r

blk="$(tput setaf 6)"       # cyan    \003[36m
grn="$(tput setaf 2)"       # green   \003[31m
wht="$(tput setaf 7)"       # white   \003[37m
rst="$(tput sgr0)"          # reset   \003[0m -- reset

bar="------------------------------------------------------------" # trackbar

[ -p "$i/$s/$c/in"  ] || exit 1
[ -e "$i/$s/$c/out" ] || { touch "$i/$s/$c/out" || exit 1; }

mark() {
	tail -n1 "$i/$s/$c/out" | {
		read -r date time nick mesg
		[ "$mesg" != "$bar" ] && printf '%s -!- %.*s\n' "$(date +"%F %R")" "$f" "${bar}${bar}${bar}" >>"$i/$s/$c/out"
	}
}

trap "stty '$(stty -g)'; kill -TERM 0" EXIT
stty -echonl -echo

tail -f -n "$h" "$i/$s/$c/out" | while IFS= read -r mesg
do
	date="${mesg%% *}" mesg="${mesg#* }"
	time="${mesg%% *}" mesg="${mesg#* }"
	nick="${mesg%% *}" mesg="${mesg#* }"

	# strip '<nick>' to 'nick'
	nick="${nick#<}" nick="${nick%>}"

	# do not notify of server messages
	[ "$nick" != '-!-' ] && printf '\a'

	# highlight date if user was referenced in the message
	case "$mesg" in *$u*) date="$(tput setaf $l)$date" ;; esac

	# pretify special symbols around words
	# *bold* _underline_ /italics/ and underline urls
	[ "$p" -ne 0 ] && mesg="$(echo "$mesg" | awk \
		-vis="$(tput sitm; tput setaf 05)" -vie="$(tput ritm)${wht}" \
		-vus="$(tput smul; tput setaf 03)" -vue="$(tput rmul)${wht}" \
		-vbs="$(tput bold; tput setaf 01)" -vbe="$(tput sgr0)${wht}" \
		-vls="$(tput smul; tput setaf 11)" -vle="$(tput rmul)${wht}" '
		function replace(l, s, r) {
			p = index(l, s) - 1
			n = p + length(s) + 1
			l = substr(l, 1, p) r substr(l, n)
			return l
		}

		{
			line = $0

			for (i=1; i<=NF; i++)
				if ($i ~ /^(http|ftp|ssh|www).+/) {
					line = replace(line, $i, ls $i le)
				} else if ($i ~ /^_[^_].*[^_]_$/) {
					line = replace(line, $i, us substr($i, 2, length($i) - 2) ue)
				} else if ($i ~ /^[*].*[*]$/) {
					line = replace(line, $i, bs $i be)
				} else if ($i ~ /^[/].*[/]$/) {
					line = replace(line, $i, is $i ie)
				}
			print line
		}
	')"

	[ "$p" -ne 0 ] && clr="$(tput setaf $(( $(printf '(%d ^ %d + %d)' "${#nick}" "'$nick" "'${nick#?}")  % 14 + 1)))" || clr="$grn"

	# let server name have a static color across all randomization functions
	[ "$p" -ne 0 ] && [ "$nick" == '-!-' ] && clr="$(tput setaf 14)"
	case "$mesg" in ACTION*) mesg="$clr$nick$rst:${mesg#ACTION}" nick="*" clr="$grn" ;; esac

	# fold lines breaking on spaces if message is greater than 'f' chars
	echo "$mesg" | fold -s -w "$f" | \
		while IFS= read -r line
		do printf '\r%s %s %*.*s %s %s\n' "${blk}${date}" "${time}${clr}" "${m}" "${m}" "${nick}" "${blk}|${wht}" "${line}${rst}"
		done
done &

while IFS= read -r line; do
	case "$line" in
		'')
			continue
			;;
		:x)
			mark && break
			;;
		:q)
			break
			;;
		:m)
			mark
			continue
			;;
		/wi" "*)
			line="/j nickserv info ${line#/wi}"
			;;
		/me" "*)
			line="ACTION${line#/me}"
			;;
		/names)
			line="/names $c"
			;;
		/op" "*)
			line="/j chanserv op $c ${line##* }"
			;;
		/deop" "*)
			line="/j chanserv deop $c ${line##* }"
			;;
		/bans)
			line="/j chanserv akick $c LIST"
			;;
		/ban" "*)
			line="/j chanserv akick $c ADD ${line##* } -- goodbye"
			;;
		/unban" "*)
			line="/j chanserv akick $c DEL ${line##* }"
			;;
		/t)
			line="/topic $c"
			;;
	esac
	printf '%s\n' "$line"
done >"$i/$s/$c/in"

