#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# monitor the given irc directory tree for changes - ignores server messages
# and spawns tmiii.sh or a new urxvt terminal with the chanel that had activity

i="${1:-$HOME/irc}"
GREP_OPTIONS=""

trap 'kill -TERM -0' EXIT

inotifywait -m --exclude "/in$" --format "%w %f" -e modify -r "$i" | \
    while read -r p f; do
        # ignore notifications files other than 'out'
        [ "$f" != "out" ] && continue
        # ignore server messages
        [ "$(awk '{ n=$3 } END { print n }' "$p$f")" = '-!-' ] && continue

        # break path down # p=/ircdir/network/channel/
        p="${p#$i}"       # p=/network/channel/
        p="${p%/*}"       # p=/network/channel
        c="${p##*/}"      # c=channel
        p="${p%/*}"       # p=/network
        n="${p##*/}"      # n=network
        # if network is empty then action is on the network view
        [ -z "$n" ] && n="$c" c=""

        opts="h=50 i="$i" n="$n" c="$c""

        ## spawn a new tmux window named <channel> in a tmux session named IRC
        env $opts tmiii.sh

        # ## spawn a new urxvt terminal with IRC-<channel> class name
        # if ! xwininfo -root -children | sed -n 's,^ \+\(0x[^ ]\+\).*("\([^"]*\)" "\([^"]*\)").*\+,"\1 \2 \3",p' | grep "${c:-$n} URxvt"
        # then env $opts urxvtc -name "IRC-${c:-$n}" -e iii.sh
        # fi
    done

