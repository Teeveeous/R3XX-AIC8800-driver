#!/bin/bash
[ "$(id -u)" != 0 ] && exec sudo "$0" "$@"
KVER="$(uname -r)"
modprobe -r aic8800_fdrv aic_load_fw 2>/dev/null
systemctl disable aic-modeswitch.service 2>/dev/null
rm -rf "/lib/modules/$KVER/kernel/drivers/net/wireless/aic8800" /lib/firmware/aic8800D80 \
       /etc/udev/rules.d/99-aic-modeswitch.rules /etc/systemd/system/aic-modeswitch.service /usr/local/sbin/aic-modeswitch.sh
systemctl daemon-reload
udevadm control --reload
depmod -a "$KVER"
