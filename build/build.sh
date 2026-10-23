#!/bin/bash
# Reproducible build of the AIC8800D80 kernel modules for the 4.4.189 kernel used by darkOS/dArkOS(RE) on the R36S.
# Output: dist/modules/{aic_load_fw,aic8800_fdrv}.ko and dist/aic8800-r36s-<date>.zip (if firmware is present).
#
# Host needs (Ubuntu/Debian): git make bc flex bison libssl-dev gcc-aarch64-linux-gnu
# Env overrides: KERNEL_DIR (reuse an existing checkout), CROSS_COMPILE, JOBS
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
KERNEL_DIR="${KERNEL_DIR:-$REPO/build/kernel-rg351}"
CROSS="${CROSS_COMPILE:-aarch64-linux-gnu-}"
JOBS="${JOBS:-$(nproc)}"
WORK="$REPO/build/work"
OUT="$REPO/dist"

for t in git make bc "${CROSS}gcc"; do command -v "$t" >/dev/null || { echo "missing tool: $t"; exit 1; }; done
[ -f /usr/include/openssl/bio.h ] || { echo "missing libssl-dev (kernel host tools need openssl headers)"; exit 1; }

# 1. Kernel source: the exact tree this firmware's kernel was built from (4.4.189, branch rg351, + exfat submodule)
if [ ! -f "$KERNEL_DIR/Makefile" ]; then
  git clone --depth=1 --branch rg351 https://github.com/lcdyk0517/arkos.bsp.4.4.git "$KERNEL_DIR"
  git -C "$KERNEL_DIR" submodule update --init --depth 1
fi

# 2. Configure exactly like the device kernel (verified: struct module size 704, init@368, exit@632 match the device's own modules)
cd "$KERNEL_DIR"
: > .scmversion                                   # keep vermagic at plain "4.4.189" (no git suffix)
# external-module builds fail on this tree's vdso rule; modules don't need it
sed -i '/^prepare: vdso_prepare/s/^/#/; /^vdso_prepare: prepare0/{s/^/#/;n;s/^/#/}' arch/arm64/Makefile
make ARCH=arm64 CROSS_COMPILE="$CROSS" clone_defconfig
make ARCH=arm64 CROSS_COMPILE="$CROSS" HOSTCFLAGS=-fcommon -j"$JOBS" modules_prepare

# 3. Build the driver (scratch copy, so the source tree stays clean). CC is overridden to bypass the tree's
#    scripts/gcc-wrapper.py, which turns every warning from a modern GCC into an error.
mkdir -p "$WORK/driver"; cp -ru "$REPO/driver/." "$WORK/driver/"   # -u: keeps already-built objects so an interrupted build resumes
make -C "$WORK/driver/aic8800" KDIR="$KERNEL_DIR" ARCH=arm64 CROSS_COMPILE="$CROSS" CC="${CROSS}gcc" \
     EXTRA_CFLAGS="-include $REPO/patches/compat44.h" -j"$JOBS"

# 4. Verify and collect
mkdir -p "$OUT/modules"
for m in aic_load_fw/aic_load_fw aic8800_fdrv/aic8800_fdrv; do
  ko="$WORK/driver/aic8800/$m.ko"
  vm="$(grep -a -o 'vermagic=[ -~]*' "$ko" | head -n1 || true)"
  echo "$(basename "$ko"): $vm"
  [ "$vm" = "vermagic=4.4.189 SMP mod_unload aarch64" ] || { echo "UNEXPECTED vermagic, refusing to package"; exit 1; }
  cp "$ko" "$OUT/modules/"
done

# 5. Package for the handheld (needs firmware, see firmware/README.md)
FW="$REPO/firmware/aic8800D80"
if [ -d "$FW" ]; then
  PKG="$OUT/pkg"; rm -rf "$PKG"; mkdir -p "$PKG/aic8800-r36s/modules"
  cp "$REPO"/package/*.sh "$PKG/"; cp "$REPO/package/aic8800-r36s/aic-modeswitch.sh" "$PKG/aic8800-r36s/"
  cp "$OUT"/modules/*.ko "$PKG/aic8800-r36s/modules/"; cp -r "$FW" "$PKG/aic8800-r36s/fw"
  chmod +x "$PKG"/*.sh "$PKG"/aic8800-r36s/*.sh
  (cd "$PKG" && rm -f "$OUT/aic8800-r36s-$(date +%Y%m%d).zip" && zip -rq "$OUT/aic8800-r36s-$(date +%Y%m%d).zip" .)
  echo "package: $OUT/aic8800-r36s-$(date +%Y%m%d).zip"
else
  echo "modules built in $OUT/modules. Add firmware to $FW to also create the handheld package (see firmware/README.md)."
fi
