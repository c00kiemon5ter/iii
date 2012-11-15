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

    # handle relay network nicks
    case "$mesg" in /NNNC/*) nick="${mesg%%>*}@$nick" mesg="${mesg#/NNNC/*> }" nick="${nick#/*/}" ;; esac

    # pretify special symbols around words
    # *bold* _underline_ /italics/ and underline urls
    mesg="$(echo "$mesg" | awk -vis="$(tput sitm; tput setaf 05)" -vie="$(tput ritm)${wht}" \
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
                if ($i ~ /^http/) {
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

    # value between 1 and 14 - avoid black and white (though there's 7 and 8 in there)
    # color value is based on the length and first and second letter of the nick
    # you may want to uncomment and try another randomization function.
    # -----
    # those functions have been chosen based on the distribution of colors for
    # the top 200 most messaged nicks on the channels I participate.
    # as one goes down the list the distribution gets more and more unequal.
    # ommited are functions that gave way too bad results (ie "%d & %d & %d").
    # occurances of white (result:7) and black(result:8) have also been used as classification factors.
    $r && clr="$(tput setaf $(( (( $(printf "%d ^ %d + %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d + %d + %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d * %d + %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d + %d ^ %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d ^ %d ^ %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d ^ %d * %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d * %d ^ %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d | %d * %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"
    #$r && clr="$(tput setaf $(( (( $(printf "%d & %d ^ %d" "${#nick}" "'$nick" "'${nick#?}") ) % 14) + 1)))" || clr="$grn"

    # let server name have a static color across all randomization functions
    $r && [ "$nick" == '-!-' ] && clr="$(tput setaf 14)"
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
        /deop*) line="/j chanserv deop $c ${line##* }"
            ;;
        /bans) line="/j chanserv akick $c LIST"
            ;;
        /ban*) line="/j chanserv akick $c ADD ${line##* } -- goodbye"
            ;;
        /unban*) line="/j chanserv akick $c DEL ${line##* }"
            ;;
        /t) line="/topic $c"
            ;;
    esac
    printf "%s\n" "$line"
done >"$i/$n/$c/in"

