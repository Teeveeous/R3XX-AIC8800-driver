# AIC8800D80 Wi-Fi for the R36S (darkOS / dArkOS 4.4.189 kernel)

Kernel modules, install scripts and a reproducible build that make **AIC8800D80 USB Wi-Fi dongles**
(e.g. the UGREEN CM762 / AX900) work on an **R36S running a dArkOS-family build with the 4.4.189 kernel**.

> **Status: experimental.** Confirmed working on one device (below). Back up your SD card before installing.

## Tested on

| | |
|---|---|
| Handheld | original R36S |
| OS | dArkOS-based Debian 13 build (release `v08272026`), kernel `4.4.189 #62`, aarch64 |
| Dongle | UGREEN CM762, AIC8800D80, USB `a69c:5723` in storage mode |
| Result | `wlan0` appears, connects, a YouTube port streams |

Not tested: Bluetooth, hot-plug while running, suspend/resume, access-point mode, other kernels/builds.

## Why this exists

The dongle ships a Windows `Setup.exe`; the Linux driver is separate (AICsemi/UGREEN publish the source).
It does not build or load on this kernel out of the box. Three things had to be right:

1. **The dongle starts as a fake USB disk** (`a69c:5723`) and must be mode-switched. `usb_modeswitch` is already on the OS; a small systemd service does it at boot and on hot-plug.
2. **The modules must be built against the kernel's real source and config.** Many `struct` layouts depend on the kernel config
   (this one has 64-byte cache lines, mutex/spinlock debugging, no `KALLSYMS`, no PCI). Built against a generic 4.4.189 tree the
   modules *loaded but silently did nothing*: the kernel looked for each module's init function at the wrong offset.
3. **Small source compatibility fix**: two renamed timer calls (`patches/compat44.h`). Everything else is the unmodified vendor driver.

USB IDs you will see: `a69c:5723` (storage) -> `a69c:8d80` (loader) -> `368b:8d85` ("AIC 8800D80", the working Wi-Fi device).

## Install (on the handheld)

You need a release zip (`aic8800-r36s-*.zip`) **plus the firmware** (see [Firmware](#firmware)).

1. Unplug the dongle.
2. Extract the zip into the Tools folder (`/opt/system/Tools/`) so the three `.sh` files sit next to the `aic8800-r36s` folder. Put the firmware files in `aic8800-r36s/fw/`. Restart EmulationStation.
3. Run **Install AIC WiFi** from the Tools menu. It writes `aic-install.log` next to the script.
4. Power off, plug the dongle in, boot, wait about a minute.
5. Connect with the OS's **Wifi** tool. Use **Collect AIC Log** if something is off.

**Remove AIC WiFi** undoes everything. If a boot ever hangs, boot with the dongle unplugged and run it.

The installer refuses to run unless `uname -r` is exactly `4.4.189`.

## Firmware

Firmware is **not included** (no license statement from the vendor). Take it from the vendor's own Linux package for your dongle
(`Linux/aic8800_linux_driver/fw/aic8800D80/`) and place the files in `aic8800-r36s/fw/` (release zip) or `firmware/aic8800D80/` (when building).

## Build from source

Needs Ubuntu/Debian with `git make bc flex bison libssl-dev rsync zip gcc-aarch64-linux-gnu`.

```bash
git clone <this repo> && cd aic8800-r36s-darkos
# optional: put firmware in firmware/aic8800D80/ to also get a ready-to-copy package
./build/build.sh
```

The script clones the kernel source the firmware was built from (`lcdyk0517/arkos.bsp.4.4`, branch `rg351`, `clone_defconfig`),
prepares it, builds the modules and **refuses to package them unless their vermagic is `4.4.189 SMP mod_unload aarch64`**.
Output goes to `dist/`.

## Adapting to another kernel/firmware build

The module layout check that mattered most: compare a module the device already loads with yours.

```bash
readelf -SW some_installed.ko | grep this_module          # section size
readelf -rW some_installed.ko | grep -E 'init_module|cleanup_module'   # init/exit offsets
```

Your build must report the same size and offsets (here: `0x2c0`, `0x170`, `0x278`). If not, you are on the wrong source/config.
Also check `modinfo` vermagic, and that your module imports no symbols the kernel doesn't export
(this kernel exports `__arch_copy_{to,from}_user`, not `__copy_*`).

## Layout

```
driver/      vendor AIC8800 driver source, unmodified
patches/     compat44.h (timer API names for 4.4)
package/     scripts + mode-switch helper that go on the handheld
build/       build.sh
firmware/    where to put the vendor firmware (not included)
```

## Licenses and credits

See [NOTICE.md](NOTICE.md). Driver source: AICsemi / UGREEN vendor package (GPL). Kernel source: `lcdyk0517/arkos.bsp.4.4`, `christianhaitian/linux`.
dArkOS by christianhaitian and contributors. Not affiliated with any of them.
