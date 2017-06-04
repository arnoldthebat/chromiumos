# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-drivers/xf86-video-ati/xf86-video-ati-7.3.0.ebuild,v 1.1 2014/01/26 17:29:30 chithanh Exp $

EAPI=4

XORG_DRI=always
inherit linux-info xorg-2

DESCRIPTION="ATI video driver"

KEYWORDS="-* amd64 x86"
IUSE="udev"

RDEPEND=">=x11-libs/libdrm-2.4.46[video_cards_radeon]
	udev? ( virtual/udev )"
DEPEND="${RDEPEND}"

PATCHES=(
	# Do not abort initialization when unable to set DRM master
	"${FILESDIR}/7.3.0-failure-to-set-drm-master-is-not-fatal.patch"
)

src_prepare() {
	for patch_file in "${PATCHES[@]}"; do
		epatch $patch_file
	done
}

src_configure() {
	XORG_CONFIGURE_OPTIONS=(
		--disable-glamor
		$(use_enable udev)
	)
	xorg-2_src_configure
}
