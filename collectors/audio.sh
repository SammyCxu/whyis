#!/bin/bash
# Audio collector
amixer get Master | tail -n1 | awk -F'[][]' '{print "volume="$2}'
cat /proc/asound/cards 2>/dev/null
