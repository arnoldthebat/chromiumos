<!-- cSpell:ignore brcm, realtek, setup, chromiumos, eclass, cros, workon, chromeos, auserver, devserver, noenable, rootfs, updatable, backlight -->

# General info
This repo is a fork of magnificent work made by [arnoldthebat](https://github.com/arnoldthebat) and it's mainly focused on preparing ChromiumOS builds with support for cheap touchscreen netbooks.

# ChromiumOS

Chromium OS is an open-source project that aims to build an operating system that provides a fast, simple, and more secure computing experience for people who spend most of their time on the web.

Clone this repo to your overlay name in your repo/src/overlays

## Setup

```bash
sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-atb\n/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass

export BOARD=amd64-atb
setup_board --board=${BOARD}
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-4_19
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos
cros_sdk -- "./setup_board" "--board=${BOARD}"
cros_sdk -- "cros_workon" "--board=${BOARD}" "start" "sys-kernel/chromeos-kernel-4_19"
```

### Build Packages

```bash
emerge-amd64-atb chromeos-factory-board
./build_packages --board=${BOARD}
```

### Build Image

```bash
export BOARD=amd64-atb
export CHROMEOS_VERSION_AUSERVER=http://chromebld.arnoldthebat.co.uk:9080/update
export CHROMEOS_VERSION_DEVSERVER=http://chromebld.arnoldthebat.co.uk:9080
./build_image --board=${BOARD} --noenable_rootfs_verification dev --disk_layout 2gb-rootfs-updatable
```

## Other hacks

### Kernel patches

Add to File: ../../chroot/etc/sandbox.conf

```bash
# Needed for kernel patches
SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v4.19/"
```

### Known Issues

* Play Store does not work.
* The Google assistant does not work.
* "This is the last automatic software and security upgrade statement" can safely be ignored since this wont prevent subsequent updates.

### Change Log 09/12/19

* Kernel updated to version 4.19
* ebuilds update
