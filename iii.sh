#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# frontend to ii for a single channel
# follows the tail of the out file
# and redirects input to the in file

: "${u:=$USER}"             # the user's nickname
: "${i:=$HOME/irc}"         # root irc dir
: "${n:=irc.oftc.net}"      # network
: "${c:=""}"                # channel - empty for network (default)
: "${m:=12}"                # max nick lenght
: "${h:=20}"                # lines from history
: "${r:=true}"              # whether to use random colors for nicks
: "${l:=3}"                 # highlight color

[ "$1" != "-r" ] && exec rlwrap -a -s 0 -r -b "(){}[],+=^#;|&%" -S "${c:-$n}> " -pgreen "$0" -r

blk="$(tput setaf 6)"       # cyan    \003[36m
grn="$(tput setaf 2)"       # green   \003[31m
wht="$(tput setaf 7)"       # white   \003[37m
rst="$(tput sgr0)"          # reset   \003[0m -- reset

bar="------------------------------------------------------------" # trackbar

[ -p "$i/$n/$c/in"  ] || exit 1
[ -e "$i/$n/$c/out" ] || { touch "$i/$n/$c/out" || exit 1; }

mark() {
    tail -n1 "$i/$n/$c/out" | {
        read -r date time nick mesg
        [ "$mesg" != "$bar" ] && printf "%s -!- %s\n" "$(date +"%F %R")" "$bar" >>"$i/$n/$c/out"
    }
}

trap "stty '$(stty -g)'; kill -TERM -0" EXIT
stty -echonl -echo

tail -f -n "$h" "$i/$n/$c/out" | while read -r date time nick mesg; do
    case "$nick" in \<*\>) nick="${nick#<}" nick="${nick%>}"; printf '\a' ;; esac
    case "$mesg" in *$u*) date="$(tput setaf $l)$date" ;; esac
    # value between 1 and 14 - avoid black and white though there's 7 and 8
    # based on the nick length and ascii code of the nick's first letter
    $r && clr="$(tput setaf $(( ((${#nick} + $(printf "%d" "'$nick")) % 14) + 1)))" || clr="$grn"
    case "$mesg" in ACTION*) mesg="$clr$nick$rst:${mesg#ACTION}" nick="*" clr="$grn" ;; esac
    printf "\r$blk%s $clr%*.*s $blk| $wht%s$rst\n" "$date $time" "$m" "$m" "$nick" "$mesg"
done &

while read -r line; do
    case "$line" in
        '') continue
            ;;
        :x) mark && break
            ;;
        :q) break
            ;;
        :m) mark
            continue
            ;;
        /wi*) line="/j nickserv info ${line#/wi}"
            ;;
        /me*) line="ACTION${line#/me}"
            ;;
        /names) line="/names $c"
            ;;
        /op*) line="/j chanserv op $c ${line##* }"
            ;;
    esac
    printf "%s\n" "$line"
done >"$i/$n/$c/in"

