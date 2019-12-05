# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils linux-info linux-mod

DESCRIPTION="Driver for Realtek RTL8723BU Wireless Adapter with Hardware ID"
HOMEPAGE="https://github.com/arnoldthebat/rtl8723bu"

CROS_WORKON_REPO="https://github.com/arnoldthebat"
CROS_WORKON_PROJECT="rtl8723bu"
CROS_WORKON_EGIT_BRANCH="master"
CROS_WORKON_BLACKLIST="1"
CROS_WORKON_COMMIT="c36c3cced3ec0c91daeb76c9e2c80a993ae61977"

# This must be inherited *after* EGIT/CROS_WORKON variables defined.
inherit git-2 cros-workon #cros-kernel2 cros-workon


LICENSE="GPL-2"
KEYWORDS="-* amd64 x86"

RESTRICT="mirror"

DEPEND="virtual/linux-sources"
RDEPEND=""

MODULE_NAMES="8723bu(kernel/drivers/net/wireless/)"

pkg_setup() {

	linux-mod_pkg_setup

	BUILD_PARAMS="-C /mnt/host/source/chroot/build/${BOARD}/var/cache/portage/sys-kernel/chromeos-kernel-4_19 M=${S}"
	BUILD_TARGETS="8723bu.ko"
}


src_install() {
	linux-mod_src_install

	dodoc "${S}/LICENSE"
}
