#!/bin/bash
[ "$(id -u)" != 0 ] && exec sudo "$0" "$@"
OUT="$(dirname "$(readlink -f "$0")")/aic-log.txt"
{
  date
  for d in /sys/bus/usb/devices/*; do [ -f "$d/idVendor" ] && echo "$(basename $d) $(cat $d/idVendor):$(cat $d/idProduct) $(cat $d/product 2>/dev/null)"; done
  echo "--- lsmod"; lsmod | grep -i aic
  echo "--- net"; ls /sys/class/net /sys/class/ieee80211
  command -v ip >/dev/null && { echo "--- ip link"; ip -br link; }
  command -v iw >/dev/null && { echo "--- iw dev"; iw dev; }
  echo "--- service"; systemctl status aic-modeswitch.service --no-pager 2>&1 | tail -n 12
  echo "--- dmesg"; dmesg | grep -iE "aic|rwnx|firmware|cfg80211|wlan|usb 1-1" | tail -n 100
} > "$OUT" 2>&1
