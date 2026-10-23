#!/bin/bash
# Waits up to 40s for an AIC dongle in storage mode (a69c:5723) and switches it to Wi-Fi mode. Never blocks boot (run as a background service).
for i in $(seq 1 40); do
  for d in /sys/bus/usb/devices/*; do
    v=$(cat "$d/idVendor" 2>/dev/null); p=$(cat "$d/idProduct" 2>/dev/null)
    if [ "$v" = a69c ]; then
      [ "$p" = 5723 ] && /usr/sbin/usb_modeswitch -v a69c -p 5723 -K -Q
      exit 0
    fi
  done
  sleep 1
done
exit 0
