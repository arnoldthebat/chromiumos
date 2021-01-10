# Copyright (c) 2013 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

DESCRIPTION="Generic ebuild which satisifies virtual/chromeos-bsp.
This is a direct dependency of virtual/target-chromium-os, but is expected
to be overridden in an overlay for each specialized board.  A typical
non-generic implementation will install any board-specific configuration
files and drivers which are not suitable for inclusion in a generic board
overlay."
HOMEPAGE="http://src.chromium.org"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
	!chromeos-base/chromeos-bsp-null
	sys-kernel/linux-firmware
	media-libs/x264
	!net-wireless/broadcom-sta
	!net-wireless/rtl8188eu
	!net-wireless/rtl8723au
	!net-wireless/rtl8723bu
	!net-wireless/rtl8812au
	!net-wireless/rtl8821ce
	www-plugins/chrome-binary-plugins
	chromeos-base/chromeos-bsp-amd64-atb
"
DEPEND="${RDEPEND}"
