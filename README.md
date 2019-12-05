<!-- cSpell:ignore brcm, realtek, setup, chromiumos, eclass, cros, workon, chromeos, auserver, devserver, noenable, rootfs, updatable, backlight -->

# ChromiumOS

Chromium OS is an open-source project that aims to build an operating system that provides a fast, simple, and more secure computing experience for people who spend most of their time on the web.

This repo is for the special builds only

All downloads are located at <http://chromium.arnoldthebat.co.uk/>.

Clone this repo to your overlay name in your repo/src/overlays

## AMD64 Setup

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

### Build AMD64 Packages

```bash
emerge-amd64-atb chromeos-factory-board
./build_packages --board=${BOARD}
```

### Build AMD64 Image

```bash
export BOARD=amd64-atb
export CHROMEOS_VERSION_AUSERVER=http://chromebld.arnoldthebat.co.uk:9080/update
export CHROMEOS_VERSION_DEVSERVER=http://chromebld.arnoldthebat.co.uk:9080
./build_image --board=${BOARD} --noenable_rootfs_verification dev --disk_layout 2gb-rootfs-updatable
```

## Vanilla Setup

```bash
sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-vanilla\n/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass

export BOARD=amd64-vanilla
setup_board --board=${BOARD}
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-4_19
```

### Build Vanilla Packages

```bash
./build_packages --board=${BOARD}
```

### Build Vanilla Image

```bash
export BOARD=amd64-vanilla
export CHROMEOS_VERSION_AUSERVER=http://chromebld.arnoldthebat.co.uk:9081/update
export CHROMEOS_VERSION_DEVSERVER=http://chromebld.arnoldthebat.co.uk:9081
./build_image --board=${BOARD} --noenable_rootfs_verification dev --disk_layout 2gb-rootfs-updatable
```

## Other hacks

### Kernel patches

Add to File: ../../chroot/etc/sandbox.conf

```bash
# Needed for kernel patches
SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v4.19/"
```

## Alpha Builds

### Known Issues

* Play Store does not work.
* The Google assistant does not work.
* "This is the last automatic software and security upgrade statement" can safely be ignored since this wont prevent subsequent updates.

### Change Log 30/09/19

* HID Sensors framework support enabled
* Thunderbolt support
* Apple SMC (Motion sensor, light sensor, keyboard backlight)

### Change Log 29/09/19

* Realtek rtl8192e wireless support
* Realtek rtl8712  wireless support
* Realtek rtl8723bs wireless support
* Additional SOC sound card support

### Change Log - 17/09/19

* Realtek rtl8188EU Wireless support
* Added in MediaTek MT7601U support
* Added in various Ethernet drivers support

### Change Log - 08/09/19

* Added in all 4.19 kernel supported Marvell Wireless cards
* Switched back to Intel IWL7K Wireless drivers
* Added in brcm80211 drivers and removed old BroadCom STA driver
