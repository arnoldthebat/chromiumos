# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Chrome OS camera HAL virtual package"
HOMEPAGE="http://src.chromium.org"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

# Set to USB HAL by default. If devices don't use USB cameras, they should
# override the ebuild in their board overlay.
RDEPEND="
	media-libs/cros-camera-hal-usb
"
