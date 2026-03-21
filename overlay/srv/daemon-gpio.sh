#!/bin/sh

S=/tmp/state
M=/tmp/mode
D=/tmp/display
C=/dev/gpiochip0

set_leds() {
  bit_mask=$(( $1 & ((1<<20)-1)))
  i=0
  leds_on=""
  while [ $i -lt 20 ]; do
    v=$(((bit_mask >> i) & 1))
    if [ $v -eq 1 ]; then
      if [ -n "$leds_on" ]; then
        leds_on="$leds_on $i=1"
      else
        leds_on="$i=1"
      fi
    else
      if [ -n "$leds_on" ]; then
        leds_on="$leds_on $i=0"
      else
        leds_on="$i=0"
      fi
    fi
    i=$((i+1))
  done
  gpioset "$C" $leds_on >/dev/null 2>&1
}

[ -f "$S" ] || echo 0 > "$S"
[ -f "$M" ]  || echo stop > "$M"

set_leds 0

on=0
while true; do
  mode="$(cat "$M" 2>/dev/null)"
  if [ -z "$mode" ]; then
    mode="stop"
  fi

  num="$(cat "$S" 2>/dev/null)"
  if [ -z "$num" ]; then
    num=0
  fi

  if [ "$mode" = "run" ]; then
    if [ $on -eq 0 ]; then
      set_leds "$num"
      echo "$num" > "$D"
      on=1
    else
      set_leds 0
      echo 0 > "$D"
      on=0
    fi
    sleep 2.2
  else
    set_leds "$num"
    on=0
    echo "$num" > "$D"
    sleep 0.1
  fi
done
