#!/bin/bash
# CPU collector
mpstat 1 1 | awk '/all/ {print "idle=" $12}'
