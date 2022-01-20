#!/bin/bash

loadAvg=$(cat /proc/loadavg)

echo "$loadAvg"

exit 0
