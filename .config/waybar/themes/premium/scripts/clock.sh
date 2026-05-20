#!/usr/bin/env bash
# Single-line clock with Pango markup: "Wed 20/05 · 16:48"
# Separator dot is enlarged via span for readability.

dstr=$(date '+%a %d/%m')
tstr=$(date '+%H:%M')

# Pango markup: subdued date, big separator, bold time
echo "<span alpha='65000'>${dstr}</span><span size='larger' alpha='60000'>  ·  </span><b>${tstr}</b>"
