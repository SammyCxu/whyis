#!/bin/bash
# wifi collector
iw dev wlan0 link 2>/dev/null
cat /proc/net/wireless 2>/dev/null
