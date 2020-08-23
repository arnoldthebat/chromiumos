<!-- cSpell:ignore brcm, realtek, setup, chromiumos, eclass, cros, workon, chromeos, auserver, devserver, noenable, rootfs, updatable, backlight, arnoldthebat -->

# ChromiumOS

Chromium OS is an open-source project that aims to build an operating system that provides a fast, simple, and more secure computing experience for people who spend most of their time on the web.

This repo is for the special builds only

All downloads are located at <http://chromium.arnoldthebat.co.uk/>.

Clone this repo to your overlay name in your repo/src/overlays for example:

```bash
cd ~/chromiumos/src/overlays/
git clone git@github.com:arnoldthebat/chromiumos.git overlay-amd64-atb
```

## AMD64 Setup

```bash
sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-atb\n/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass

export BOARD=amd64-atb
setup_board --board=${BOARD}
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-4_14
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos
cros_sdk -- "setup_board" "--board=${BOARD}"
cros_sdk -- "cros_workon" "--board=${BOARD}" "start" "sys-kernel/chromeos-kernel-4_14"
```

### Build AMD64 Packages

```bash
./build_packages --board=${BOARD}
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos
cros_sdk -- "./build_packages" "--board=${BOARD}"
```

### Build AMD64 Image

```bash
export BOARD=amd64-atb
export CHROMEOS_VERSION_AUSERVER=http://chromebld.arnoldthebat.co.uk:8080/update
export CHROMEOS_VERSION_DEVSERVER=http://chromebld.arnoldthebat.co.uk:8080
./build_image --board=${BOARD} --noenable_rootfs_verification dev
```

## Other hacks

### Kernel patches

Add to File: ../../chroot/etc/sandbox.conf

```bash
# Needed for kernel patches
SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v4.14/"
```

## Alpha Builds

### Known Issues

* Play Store does not work.
* The Google assistant does not work.

### Change Log 24/11/19

* Realtek rtl8821ce wireless support

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

* Added in all 4.14 kernel supported Marvell Wireless cards
* Switched back to Intel IWL7K Wireless drivers
* Added in brcm80211 drivers and removed old BroadCom STA driver
