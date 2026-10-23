#!/bin/bash
# v3: AIC8800D80 Wi-Fi modules built against the real rg351 kernel source/config + auto mode-switch.
# Run from the ES Tools menu with the dongle UNPLUGGED, then power off, plug it in, and boot.
[ "$(id -u)" != 0 ] && exec sudo "$0" "$@"
HERE="$(dirname "$(readlink -f "$0")")"
PKG="$HERE/aic8800-r36s"
LOG="$HERE/aic-install.log"
KVER="$(uname -r)"
{
  date; echo "kernel: $KVER"
  if [ "$KVER" != "4.4.189" ]; then echo "Kernel is not 4.4.189, aborting."; exit 1; fi
  if ! ls "$PKG"/fw/*8800d80* >/dev/null 2>&1; then
    echo "No firmware found in $PKG/fw/."
    echo "Copy the vendor's aic8800D80 firmware files into that folder first (see README, 'Firmware')."
    exit 1
  fi
  modprobe -r aic8800_fdrv aic_load_fw 2>/dev/null
  DEST="/lib/modules/$KVER/kernel/drivers/net/wireless/aic8800"
  mkdir -p "$DEST"
  cp -v "$PKG/modules/aic_load_fw.ko" "$PKG/modules/aic8800_fdrv.ko" "$DEST/"
  FW=/lib/firmware/aic8800D80
  mkdir -p "$FW"; rm -rf "$FW/fw"
  find "$PKG/fw" -maxdepth 1 -type f ! -name '._*' -exec cp -v {} "$FW/" \;
  install -m 755 "$PKG/aic-modeswitch.sh" /usr/local/sbin/aic-modeswitch.sh
  cat > /etc/systemd/system/aic-modeswitch.service <<'UNIT'
[Unit]
Description=Switch AIC Wi-Fi dongle out of storage mode
[Service]
Type=simple
ExecStart=/usr/local/sbin/aic-modeswitch.sh
[Install]
WantedBy=multi-user.target
UNIT
  cat > /etc/udev/rules.d/99-aic-modeswitch.rules <<'RULE'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5723", TAG+="systemd", ENV{SYSTEMD_WANTS}+="aic-modeswitch.service"
RULE
  systemctl daemon-reload
  systemctl enable aic-modeswitch.service
  udevadm control --reload
  depmod -a "$KVER"
  echo "--- module vermagic"; modinfo "$DEST/aic8800_fdrv.ko" | grep -E "vermagic|depends"
  echo "--- installed firmware"; ls "$FW"
  echo "Done. Power off, plug the dongle in, then boot."
} > "$LOG" 2>&1
