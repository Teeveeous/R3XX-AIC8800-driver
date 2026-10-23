# Firmware (not included)

The AIC8800D80 needs its firmware files at runtime. They are **not** included in this repository because they come
with no license statement from the vendor, so redistribution rights are unclear.

Get them from the vendor's own Linux driver package for your dongle (e.g. the UGREEN CM762 download page,
`Linux/aic8800_linux_driver/fw/aic8800D80/`) and place the folder here as `firmware/aic8800D80/`
(it should contain files like `fmacfw_8800d80_u02.bin`, `fw_patch_8800d80_u02.bin`, `lmacfw_rf_8800d80_u02.bin`, ...).
`build/build.sh` then includes it in the package for the handheld.
