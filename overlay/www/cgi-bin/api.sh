#!/bin/sh
S=/tmp/state
M=/tmp/mode
D=/tmp/display
action="state"
query="$QUERY_STRING"

[ -f "$S" ] || echo 0 > "$S"
[ -f "$M" ] || echo stop > "$M"

case "$query" in
  *action=start*)  action="start" ;;
  *action=stop*)   action="stop" ;;
  *action=all*) action="all" ;;
  *action=off*)    action="off" ;;
  *action=toggle*) action="toggle" ;;
  *action=random*) action="random" ;;
esac

idx="$(echo "$query" | sed -n 's/.*idx=\([0-9][0-9]*\).*/\1/p')"
case "$action" in
  start) echo run > "$M" ;;
  random) echo $((RANDOM % (1<<20))) > "$S" ;;
  all) echo $(( (1<<20) - 1 )) > "$S" ;;
  stop)   echo stop > "$M" ;;
  off)    echo 0 > "$S" ;;
  toggle)
    if [ -n "$idx" ] && [ "$idx" -ge 0 ] 2>/dev/null && [ "$idx" -lt 20 ] 2>/dev/null; then
      state="$(cat "$S" 2>/dev/null)"; [ -n "$state" ] || state=0
      state=$(( state ^ (1<<idx) ))
      echo "$state" > "$S"
    fi
    ;;
esac

mode="$(cat "$M")"
state="$(cat "$D" 2>/dev/null)"; [ -n "$state" ] || state=0

i=0
leds_on=""
while [ $i -lt 20 ]; do
  if [ $(((state >> i) & 1)) -eq 1 ]; then
    if [ -n "$leds_on" ]; then
      leds_on="$leds_on,$i"
    else
      leds_on="$i"
    fi
  fi
  i=$((i+1))
done

printf 'Content-Type: application/json\n\n'
printf '{ "mode":"%s", "state":%s, "leds_on":[%s] }\n' "$mode" "$state" "$leds_on"
