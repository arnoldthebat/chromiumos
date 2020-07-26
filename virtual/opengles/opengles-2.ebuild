# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Virtual for OpenGLES implementations"

SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="media-libs/mesa-llvmpipe[egl,gles2]"
RDEPEND="${DEPEND}"
