# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils linux-info linux-mod

DESCRIPTION="Broadcom's IEEE 802.11a/b/g/n hybrid Linux device driver"
HOMEPAGE="https://www.broadcom.com/support/802.11"

CROS_WORKON_REPO="https://github.com/arnoldthebat"
CROS_WORKON_PROJECT="broadcom-sta_amd64"
CROS_WORKON_EGIT_BRANCH="master"
CROS_WORKON_BLACKLIST="1"
CROS_WORKON_COMMIT="7ee8dfd9150f761416ffe7998ce45e437c6bf797"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit git-2 cros-workon #cros-kernel2 cros-workon


LICENSE="Broadcom"
KEYWORDS="-* amd64 x86"

RESTRICT="mirror"

DEPEND="virtual/linux-sources"
RDEPEND=""

MODULE_NAMES="wl(net/wireless)"
MODULESD_WL_ALIASES=("wlan0 wl")

pkg_setup() {
	# bug #300570
	# NOTE<lxnay>: module builds correctly anyway with b43 and SSB enabled
	# make checks non-fatal. The correct fix is blackisting ssb and, perhaps
	# b43 via udev rules. Moreover, previous fix broke binpkgs support.
	CONFIG_CHECK="~!B43 ~!BCMA ~!SSB"
	CONFIG_CHECK2="LIB80211 ~!MAC80211 ~LIB80211_CRYPT_TKIP"
	ERROR_B43="B43: If you insist on building this, you must blacklist it!"
	ERROR_BCMA="BCMA: If you insist on building this, you must blacklist it!"
	ERROR_SSB="SSB: If you insist on building this, you must blacklist it!"
	ERROR_LIB80211="LIB80211: Please enable it. If you can't find it: enabling the driver for \"Intel PRO/Wireless 2100\" or \"Intel PRO/Wireless 2200BG\" (IPW2100 or IPW2200) should suffice."
	ERROR_MAC80211="MAC80211: If you insist on building this, you must blacklist it!"
	ERROR_PREEMPT_RCU="PREEMPT_RCU: Please do not set the Preemption Model to \"Preemptible Kernel\"; choose something else."
	ERROR_LIB80211_CRYPT_TKIP="LIB80211_CRYPT_TKIP: You will need this for WPA."
	if kernel_is ge 3 8 8; then
		CONFIG_CHECK="${CONFIG_CHECK} ${CONFIG_CHECK2} CFG80211 ~!PREEMPT_RCU ~!PREEMPT"
	elif kernel_is ge 2 6 32; then
		CONFIG_CHECK="${CONFIG_CHECK} ${CONFIG_CHECK2} CFG80211"
	elif kernel_is ge 2 6 31; then
		CONFIG_CHECK="${CONFIG_CHECK} ${CONFIG_CHECK2} WIRELESS_EXT ~!MAC80211"
	elif kernel_is ge 2 6 29; then
		CONFIG_CHECK="${CONFIG_CHECK} ${CONFIG_CHECK2} WIRELESS_EXT COMPAT_NET_DEV_OPS"
	else
		CONFIG_CHECK="${CONFIG_CHECK} IEEE80211 IEEE80211_CRYPT_TKIP"
	fi

	linux-mod_pkg_setup

	#BUILD_PARAMS="-C ${KV_DIR} M=${S}"
	BUILD_PARAMS="-C /mnt/host/source/chroot/build/${BOARD}/var/cache/portage/sys-kernel/chromeos-kernel-4_14 M=${S}"
	BUILD_TARGETS="wl.ko"
}


src_install() {
	linux-mod_src_install

	dodoc "${S}/lib/LICENSE.txt"
}
