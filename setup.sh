#!/bin/bash
# Run from outside cros_sdk

sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-atb/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass
export BOARD=amd64-atb
cd ${HOME}/chromiumos

# Note this will prompt for sudo creds - better to do a sudo based command up front therefore
cros_sdk -- "setup_board" "--board=${BOARD}"
cros_sdk -- "cros_workon" "--board=${BOARD}" "start" "sys-kernel/chromeos-kernel-4_14"

sudo touch ~/chromiumos/chroot/etc/sandbox.d/50-chrome
sudo echo "SANDBOX_WRITE=\"${HOME}/depot_tools\"" | sudo tee  ${HOME}/chromiumos/chroot/etc/sandbox.d/50-chrome
sudo echo "SANDBOX_WRITE=\"/mnt/host/source/src/third_party/kernel/v4.14\"" | sudo tee -a ${HOME}/chromiumos/chroot/etc/sandbox.d/50-chrome
