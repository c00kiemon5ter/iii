#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# wrapper around iii.sh
# spawns iii.sh in a tmux session named IRC with the channel as title
# accepts all env vars iii.sh accepts plus 't' which sets the terminal

## collect options from env - all opts to iii.sh should be set here
opts="TERM="${t:-rxvt-unicode}" m="$m" h="$h" r=$r u="$u" l="$l" i="$i" n="$n" c="$c""

## spawn a new tmux window named <channel> in a tmux session named IRC
if ! tmux list-sessions | awk -v r=1 '$1 == "IRC:" { exit r=0 } END { exit r }'
then urxvtc -name "IRC-tmux" -e tmux new-session -s IRC -n "${c:-$n}" "$opts iii.sh"
elif ! tmux list-windows -t IRC | awk -v r=1 -v m="${c:-$n}" '$2 ~ "^"m"[*!-]*$" { print $2; exit r=0 } END { exit r }'
then tmux new-window -t IRC -n "${c:-$n}" -d "$opts iii.sh"
fi

