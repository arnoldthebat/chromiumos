# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils linux-info linux-mod

DESCRIPTION="rtl8723bs SDIO driver"
CROS_WORKON_REPO="https://github.com/arnoldthebat"
CROS_WORKON_PROJECT="rtl8723bs"
CROS_WORKON_EGIT_BRANCH="master"
CROS_WORKON_BLACKLIST="1"
CROS_WORKON_COMMIT="7db8c93ca2d83612e6e53749a7974149df0fbff2"


# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit git-2 cros-workon #cros-kernel2 cros-workon

LICENSE="GPL-2"
SLOT="0"

KEYWORDS="-* amd64 x86"

DEPEND="virtual/linux-sources"
RDEPEND=""

MODULE_NAMES="r8723bs(net/wireless)"

pkg_setup() {
	linux-mod_pkg_setup
	BUILD_TARGETS=modules
}

src_compile() {
	linux-mod_src_compile
}

pkg_preinst() {
	ewarn "**** Adding Files to Firmware *****"
	insinto /lib/firmware/rtlwifi/
	doins ${WORKDIR}/rtl8723bs/rtl8723bs_nic.bin
	doins ${WORKDIR}/rtl8723bs/rtl8723bs_wowlan.bin
}


