<!-- cSpell:ignore brcm, realtek, setup, chromiumos, eclass, cros, workon, chromeos, auserver, devserver, noenable, rootfs, updatable, backlight, arnoldthebat, menuconfig, kconfig, kconfigs -->

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

Setup the board

```bash
sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-atb\n/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass
```

### Special Build Setup

Running from inside cros_sdk:

```bash
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

### Alpha Build Setup

Running from inside cros_sdk:

```bash
export BOARD=amd64-atb
setup_board --board=${BOARD}
# cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-5_4
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos
cros_sdk -- "setup_board" "--board=${BOARD}"
# cros_sdk -- "cros_workon" "--board=${BOARD}" "start" "sys-kernel/chromeos-kernel-5_4"
```

### Special Build Kernel

Running from inside cros_sdk:

```bash
export BOARD=amd64-atb
cd ~/trunk/src/third_party/kernel/v4.14/
make menuconfig KCONFIG_CONFIG=/mnt/host/source/src/overlays/overlay-${BOARD}/kconfigs/.config
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos/src/third_party/kernel/v4.14/
make menuconfig KCONFIG_CONFIG=${HOME}/chromiumos/src/overlays/overlay-${BOARD}/kconfigs/.config
```

### Alpha Build Kernel

Running from inside cros_sdk:

```bash
export BOARD=amd64-atb
cd ~/trunk/src/third_party/kernel/v5.4/
make menuconfig KCONFIG_CONFIG=/mnt/host/source/src/overlays/overlay-${BOARD}/kconfigs/.config
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos/src/third_party/kernel/v5.4/
make menuconfig KCONFIG_CONFIG=${HOME}/chromiumos/src/overlays/overlay-${BOARD}/kconfigs/.config
```

Amend/Add/Remove as needed for your requirements.

### Build AMD64 Packages

Running from inside cros_sdk:

```bash
export BOARD=amd64-atb
cd ~/trunk/src/scripts/
./build_packages --board=${BOARD}
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-atb
cd ${HOME}/chromiumos
cros_sdk -- "./build_packages" "--board=${BOARD}"
```

This will take a long time!

### Build AMD64 Image

Running from inside cros_sdk:

```bash
export BOARD=amd64-atb
export CHROMEOS_VERSION_AUSERVER=http://chromeota.arnoldthebat.co.uk:8080/update
export CHROMEOS_VERSION_DEVSERVER=http://chromeota.arnoldthebat.co.uk:8080
./build_image --board=${BOARD} --noenable_rootfs_verification dev
```

## Copying to USB

Running from outside cros_sdk:

```bash
sudo dd if=/path/to/chromiumos_image.bin of=/dev/sdb bs=4096 status=progress && sync
```

## Other hacks

### Alpha Kernel patches

Running from inside cros_sdk:

```bash
sudo tee -a ~/trunk/chroot/etc/sandbox.conf <<<'SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v5.4/"'
```

Running from outside cros_sdk:

```bash
sudo tee -a ${HOME}/chromiumos/chroot/etc/sandbox.conf <<<'SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v5.4/"'
```

### Special Kernel patches

Running from inside cros_sdk:

```bash
sudo tee -a ~/trunk/chroot/etc/sandbox.conf <<<'SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v4.14/"'
```

Running from outside cros_sdk:

```bash
sudo tee -a ${HOME}/chromiumos/chroot/etc/sandbox.conf <<<'SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v4.14/"'
```

## Change Logs

* [Alpha Builds](./CHANGELOG-ALPHA.md)
* [Special Builds](./CHANGELOG-SPECIAL.md)
