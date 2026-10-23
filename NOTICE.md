# Notice

- **Driver source (`driver/`)** is the AIC8800D80 Linux driver from the UGREEN CM762 / AICsemi vendor package, included unmodified.
  Its modules declare `MODULE_LICENSE("GPL")`. The vendor package has no separate license file; copyright belongs to its authors.
  The repository's own scripts and patches are released under GPL-2.0-only (see `LICENSE`) to stay compatible with the driver.
  If you ship the prebuilt `.ko` files, ship the corresponding source too (this repository).
- **Firmware** (`aic8800D80/*.bin`) is **not included**. It is proprietary vendor material with no license statement.
- **Not included:** the vendor's Windows installer, and the Linux kernel tree (fetched from its own repositories by `build/build.sh`).
- This is not legal advice. If you are a rights holder and want something changed or removed, please open an issue.
- Provided as is, without warranty. Installing kernel modules can make a device unstable; back up your SD card first.
