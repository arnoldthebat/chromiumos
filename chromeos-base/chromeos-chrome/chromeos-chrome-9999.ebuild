# Copyright 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Usage: by default, downloads chromium browser from the build server.
# If CHROME_ORIGIN is set to one of {SERVER_SOURCE, LOCAL_SOURCE, LOCAL_BINARY},
# the build comes from the chromimum source repository (gclient sync),
# build server, locally provided source, or locally provided binary.
# If you are using SERVER_SOURCE, a gclient template file that is in the files
# directory which will be copied automatically during the build and used as
# the .gclient for 'gclient sync'.
# If building from LOCAL_SOURCE or LOCAL_BINARY specifying BUILDTYPE
# will allow you to specify "Debug" or another build type; "Release" is
# the default.
# gclient is expected to be in ~/depot_tools if EGCLIENT is not set
# to gclient path.

EAPI="4"
inherit autotest-deponly binutils-funcs cros-constants eutils flag-o-matic git-2 multilib toolchain-funcs

DESCRIPTION="Open-source version of Google Chrome web browser"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
if use chrome_internal; then
	LICENSE+=" ( Google-TOS )"
fi
SLOT="0"
KEYWORDS="*"
IUSE="
	afdo_use
	+accessibility
	app_shell
	asan
	+build_tests
	+chrome_debug
	chrome_debug_tests
	chrome_internal
	chrome_media
	+chrome_remoting
	clang
	component_build
	cups
	envoy
	evdev_gestures
	+fonts
	+gn
	+gold
	hardfp
	+highdpi
	internal_gles_conform
	mojo
	+nacl
	neon
	opengl
	opengles
	ozone
	+runhooks
	+v4l2_codec
	v4lplugin
	vaapi
	verbose
	vtable_verify
	xkbcommon
	X
	"
REQUIRED_USE="asan? ( clang )"

OZONE_PLATFORM_PREFIX=ozone_platform_
OZONE_PLATFORMS=(gbm cast test egltest caca)
IUSE_OZONE_PLATFORMS="${OZONE_PLATFORMS[@]/#/${OZONE_PLATFORM_PREFIX}}"
IUSE+=" ${IUSE_OZONE_PLATFORMS}"
OZONE_PLATFORM_DEFAULT_PREFIX=ozone_platform_default_
IUSE_OZONE_PLATFORM_DEFAULTS="${OZONE_PLATFORMS[@]/#/${OZONE_PLATFORM_DEFAULT_PREFIX}}"
IUSE+=" ${IUSE_OZONE_PLATFORM_DEFAULTS}"
REQUIRED_USE+=" ozone? ( ^^ ( ${IUSE_OZONE_PLATFORM_DEFAULTS} ) )"

# Do not strip the nacl_helper_bootstrap binary because the binutils
# objcopy/strip mangles the ELF program headers.
# TODO(mcgrathr,vapier): This should be removed after portage's prepstrip
# script is changed to use eu-strip instead of objcopy and strip.
STRIP_MASK+=" */nacl_helper_bootstrap"

# Portage version without optional portage suffix.
CHROME_VERSION="${PV/_*/}"

CHROME_SRC="chrome-src"
if use chrome_internal; then
	CHROME_SRC="${CHROME_SRC}-internal"
fi

# CHROME_CACHE_DIR is used for storing output artifacts, and is always a
# regular directory inside the chroot (i.e. it's never mounted in, so it's
# always safe to use cp -al for these artifacts).
if [[ -z ${CHROME_CACHE_DIR} ]] ; then
	CHROME_CACHE_DIR="/var/cache/chromeos-chrome/${CHROME_SRC}"
fi
addwrite "${CHROME_CACHE_DIR}"

# CHROME_DISTDIR is used for storing the source code, if any source code
# needs to be unpacked at build time (e.g. in the SERVER_SOURCE scenario.)
# It will be mounted into the chroot, so it is never safe to use cp -al
# for these files.
if [[ -z ${CHROME_DISTDIR} ]] ; then
	CHROME_DISTDIR="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/${CHROME_SRC}"
fi
addwrite "${CHROME_DISTDIR}"

# chrome destination directory
CHROME_DIR=/opt/google/chrome
D_CHROME_DIR="${D}/${CHROME_DIR}"
RELEASE_EXTRA_CFLAGS=()

# For compilation/local chrome
BUILDTYPE="${BUILDTYPE:-Release}"
BOARD="${BOARD:-${SYSROOT##/build/}}"
BUILD_OUT="${BUILD_OUT:-out_${BOARD}}"
# WARNING: We are using a symlink now for the build directory to work around
# command line length limits. This will cause problems if you are doing
# parallel builds of different boards/variants.
# Unsetting BUILD_OUT_SYM will revert this behavior
BUILD_OUT_SYM="c"

AFDO_BZ_SUFFIX=".bz2"
AFDO_LOCATION=${AFDO_GS_DIRECTORY:-"gs://chromeos-prebuilt/afdo-job/canonicals/"}

# This dictionary contains one entry per architecture. The value for each
# entry is the appropriate AFDO profile for the current version of Chrome.
declare -A AFDO_FILE
# The following entries into the AFDO_FILE dictionary are set automatically
# by the PFQ builder. Don't change the format of the lines or modify by hand.
AFDO_FILE["amd64"]="chromeos-chrome-amd64-55.0.2883.105_rc-r1.afdo"
AFDO_FILE["x86"]="chromeos-chrome-amd64-55.0.2883.105_rc-r1.afdo"
AFDO_FILE["arm"]="chromeos-chrome-amd64-55.0.2883.105_rc-r1.afdo"

# This dictionary can be used to manually override the setting for the
# AFDO profile file. Any non-empty values in this array will take precedence
# over the values in the AFDO_FILE dictionary.
# Normally one would not set any value for the elements in the dictionary.
# This is only used when there is some kind of problem with the AFDO profile
# generation process and one needs to force the use of an older profile.
declare -A AFDO_FROZEN_FILE
AFDO_FROZEN_FILE["amd64"]=""
AFDO_FROZEN_FILE["x86"]=""
AFDO_FROZEN_FILE["arm"]=""

add_afdo_files() {
	local a f
	for a in "${!AFDO_FILE[@]}" ; do
		f=${AFDO_FILE[${a}]}
		if [[ -n ${f} ]]; then
			SRC_URI+=" afdo_use? ( ${a}? ( ${AFDO_LOCATION}${f}${AFDO_BZ_SUFFIX} ) )"
		fi
	done
	for a in "${!AFDO_FROZEN_FILE[@]}" ; do
		f=${AFDO_FROZEN_FILE[${a}]}
		if [[ -n ${f} ]]; then
			SRC_URI+=" afdo_use? ( ${a}? ( ${AFDO_LOCATION}${f}${AFDO_BZ_SUFFIX} ) )"
		fi
	done
}

add_afdo_files

RESTRICT="mirror"

RDEPEND="${RDEPEND}
	app-arch/bzip2
	fonts? ( chromeos-base/chromeos-fonts )
	dev-libs/atk
	dev-libs/glib
	dev-libs/nspr
	>=dev-libs/nss-3.12.2
	dev-libs/libxml2
	dev-libs/dbus-glib
	x11-libs/cairo
	x11-libs/pango
	>=media-libs/alsa-lib-1.0.19
	media-libs/fontconfig
	media-libs/freetype
	media-libs/harfbuzz
	x11-libs/libdrm
	ozone_platform_gbm? ( media-libs/minigbm )
	media-libs/libpng
	v4lplugin? ( media-libs/libv4lplugins )
	>=media-sound/adhd-0.0.1-r310
	net-misc/wget
	cups? ( net-print/cups )
	opengl? ( virtual/opengl )
	opengles? ( virtual/opengles )
	sys-apps/pciutils
	virtual/udev
	sys-libs/libcap
	chrome_remoting? ( sys-libs/pam )
	sys-libs/zlib
	vaapi? ( x11-libs/libva )
	X? (
		x11-apps/setxkbmap
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXcursor
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libXrender
		chrome_remoting? ( x11-libs/libXtst )
	)
	xkbcommon? (
		x11-libs/libxkbcommon
		x11-misc/xkeyboard-config
	)
	evdev_gestures? (
		chromeos-base/gestures
		chromeos-base/libevdev
	)
	accessibility? ( app-accessibility/brltty )
	"


DEPEND="${DEPEND}
	${RDEPEND}
	chromeos-base/protofiles
	>=dev-util/gperf-3.0.3
	>=dev-util/pkgconfig-0.23
	arm? ( x11-libs/libdrm )
"

PATCHES=()

AUTOTEST_COMMON="src/chrome/test/chromeos/autotest/files"
AUTOTEST_DEPS="${AUTOTEST_COMMON}/client/deps"
AUTOTEST_DEPS_LIST="chrome_test page_cycler_dep perf_data_dep telemetry_dep"

IUSE="${IUSE} +autotest"

export CHROMIUM_HOME=/usr/$(get_libdir)/chromium-browser

QA_TEXTRELS="*"
QA_EXECSTACK="*"
QA_PRESTRIPPED="*"

use_nacl() {
	# 32bit asan conflicts with nacl: crosbug.com/38980
	! (use asan && [[ ${ARCH} == "x86" ]]) && \
	! use component_build && use nacl
}

# Like the `usex` helper:
# Usage: echox [int] [echo-if-true] [echo-if-false]
# If [int] is 0, then echo the 2nd arg (default of yes), else
# echo the 3rd arg (default of no).
echox() {
	# Like the `usex` helper.
	[[ ${1:-$?} -eq 0 ]] && echo "${2:-yes}" || echo "${3:-no}"
}
echo10() { echox ${1:-$?} 1 0 ; }
echotf() { echox ${1:-$?} true false ; }
use10()  { usex $1 1 0 ; }
usetf()  { usex $1 true false ; }
set_build_defines() {
	# General build defines.
	BUILD_DEFINES=(
		"sysroot=${SYSROOT}"
		"linux_link_libbrlapi=$(use10 accessibility)"
		"use_brlapi=$(use10 accessibility)"
		"${EXTRA_BUILD_ARGS}"
		"system_libdir=$(get_libdir)"
		"pkg-config=$(tc-getPKG_CONFIG)"
		"use_v4l2_codec=$(use10 v4l2_codec)"
		"use_v4lplugin=$(use10 v4lplugin)"
		"use_vtable_verify=$(use10 vtable_verify)"
		"use_ozone=$(use10 ozone)"
		"use_evdev_gestures=$(use10 evdev_gestures)"
		"use_xkbcommon=$(use10 xkbcommon)"
		"internal_gles2_conform_tests=$(use10 internal_gles_conform)"
		# Use the ChromeOS toolchain and not the one bundled with Chromium.
		"linux_use_bundled_binutils=0"
		"linux_use_bundled_gold=0"
		"linux_use_gold_flags=$(use10 gold)"
		"linux_use_debug_fission=0"
		"remoting=$(use10 chrome_remoting)"
		"chromeos=1"
		"disable_nacl=$(! use_nacl; echo10)"
		"icu_use_data_file_flag=1"
		"use_cras=1"
		"use_system_minigbm=1"
		"use_system_harfbuzz=1"
		"use_cups=$(use10 cups)"

		# Clang features.
		asan=$(use10 asan)
		clang=$(use10 clang)
		clang_use_chrome_plugins=0
		host_clang=0
	)
	BUILD_ARGS=(
		is_debug=false
		"${EXTRA_GN_ARGS}"
		use_v4l2_codec=$(usetf v4l2_codec)
		use_v4lplugin=$(usetf v4lplugin)
		use_ozone=$(usetf ozone)
		use_evdev_gestures=$(usetf evdev_gestures)
		use_xkbcommon=$(usetf xkbcommon)
		# Use the ChromeOS toolchain and not the one bundled with Chromium.
		linux_use_bundled_binutils=false
		use_debug_fission=false
		enable_remoting=$(usetf chrome_remoting)
		enable_nacl=$(use_nacl; echotf)
		icu_use_data_file=true
		use_cras=true
		# use_system_minigbm is set under 'if use ozone' below.
		use_system_harfbuzz=true
		use_cups=$(usetf cups)

		# Clang features.
		is_asan=$(usetf asan)
		is_clang=$(usetf clang)
		cros_host_is_clang=$(usetf clang)
		clang_use_chrome_plugins=false
	)
	# BUILD_STRING_ARGS needs appropriate quoting. So, we keep them separate and
	# add them to BUILD_ARGS at the end.
	BUILD_STRING_ARGS=(
		target_sysroot="${SYSROOT}"
		system_libdir="$(get_libdir)"
		pkg_config="$(tc-getPKG_CONFIG)"
		target_os=chromeos
	)
	use internal_gles_conform && BUILD_ARGS+=( internal_gles2_conform_tests=true )

	# Disable tcmalloc on ARMv6 since it fails to build (crbug.com/181385)
	if [[ ${CHOST} == armv6* ]]; then
		BUILD_DEFINES+=( use_allocator=none )
		BUILD_ARGS+=( arm_version=6 )
		BUILD_STRING_ARGS+=( use_allocator=none )
	fi

	if use ozone; then
		local platform
		for platform in ${OZONE_PLATFORMS[@]}; do
			local flag="${OZONE_PLATFORM_DEFAULT_PREFIX}${platform}"
			if use "${flag}"; then
				BUILD_DEFINES+=("ozone_platform=${platform}")
				BUILD_STRING_ARGS+=(ozone_platform="${platform}")
			fi
		done
		BUILD_DEFINES+=(
			"ozone_auto_platforms=0"
		)
		BUILD_ARGS+=(
			ozone_auto_platforms=false
		)
		for platform in ${IUSE_OZONE_PLATFORMS}; do
			if use "${platform}"; then
				BUILD_DEFINES+=("${platform}=1")
				BUILD_ARGS+=("${platform}"=true)
			fi
		done
		if use "ozone_platform_gbm"; then
			BUILD_ARGS+=(use_system_minigbm=true)
		fi
	fi

	# Set proper BUILD_DEFINES for the arch
	case "${ARCH}" in
	x86)
		BUILD_DEFINES+=( target_arch=ia32 )
		BUILD_STRING_ARGS+=( target_cpu=x86 )
		;;
	arm)
		BUILD_DEFINES+=(
			target_arch=arm
			arm_float_abi=$(usex hardfp hard softfp)
			arm_neon=$(use10 neon)
		)
		BUILD_ARGS+=(
			arm_use_neon=$(usetf neon)
		)
		BUILD_STRING_ARGS+=(
			target_cpu=arm
			arm_float_abi=$(usex hardfp hard softfp)
		)
		if [[ -n "${ARM_FPU}" ]]; then
			BUILD_DEFINES+=( arm_fpu="${ARM_FPU}" )
		fi
		;;
	amd64)
		BUILD_DEFINES+=( target_arch=x64 )
		BUILD_STRING_ARGS+=( target_cpu=x64 )
		;;
	mips)
		local mips_arch target_arch

		mips_arch="$($(tc-getCPP) ${CFLAGS} ${CPPFLAGS} -E -P - <<<_MIPS_ARCH)"
		# Strip away any enclosing quotes.
		mips_arch="${mips_arch//\"}"
		# TODO(benchan): Use tc-endian from toolchain-func to determine endianess
		# when Chrome later cares about big-endian.
		case "${mips_arch}" in
		mips64*)
			target_arch=mips64el
			;;
		*)
			target_arch=mipsel
			;;
		esac

		BUILD_DEFINES+=(
			target_arch="${target_arch}"
			mips_arch_variant="${mips_arch}"
		)
		BUILD_STRING_ARGS+=(
			target_cpu="${target_arch}"
			mips_arch_variant="${mips_arch}"
		)
		;;
	*)
		die "Unsupported architecture: ${ARCH}"
		;;
	esac

	if use chrome_internal; then
		# Adding chrome branding specific variables and GYP_DEFINES.
		BUILD_DEFINES+=( branding=Chrome buildtype=Official )
		BUILD_ARGS+=( is_chrome_branded=true is_official_build=true )
		# This test can only be build from internal sources
		BUILD_DEFINES+=( internal_gles2_conform_tests=1 )
		BUILD_ARGS+=( internal_gles2_conform_tests=true )
		export CHROMIUM_BUILD='_google_Chrome'
		export OFFICIAL_BUILD='1'
		export CHROME_BUILD_TYPE='_official'

		# For internal builds, don't remove webcore debug symbols by default.
		REMOVE_WEBCORE_DEBUG_SYMBOLS=${REMOVE_WEBCORE_DEBUG_SYMBOLS:-0}
	elif use chrome_media; then
		echo "Building Chromium with additional media codecs and containers."
		BUILD_DEFINES+=( ffmpeg_branding=ChromeOS proprietary_codecs=1 )
		BUILD_ARGS+=( proprietary_codecs=true )
		BUILD_STRING_ARGS+=( ffmpeg_branding=ChromeOS )
	fi

	# This saves time and bytes.
	if [[ "${REMOVE_WEBCORE_DEBUG_SYMBOLS:-1}" == "1" ]]; then
		BUILD_DEFINES+=( remove_webcore_debug_symbols=1 )
	fi

	if use clang; then
		BUILD_DEFINES+=(
			werror=
		)
		BUILD_ARGS+=(
			treat_warnings_as_errors=false
		)
		# The chrome build system will add -m32 for 32bit arches, and
		# clang defaults to 64bit because our cros_sdk is 64bit default.
		export CC="clang" CXX="clang++"
	else
		cros_use_gcc
	fi

	if use component_build; then
		BUILD_DEFINES+=( component=shared_library )
		BUILD_ARGS+=( is_component_build=true )
	fi

	# TODO(davidjames): Pass in all CFLAGS this way, once gyp is smart enough
	# to accept cflags that only apply to the target.
	if use chrome_debug; then
		if use x86 || use arm; then
			# Use debug fission to avoid 4GB limit of ELF32 (see crbug.com/595763).
			# Using -g1 causes problems with crash server (see crbug.com/601854).
			RELEASE_EXTRA_CFLAGS+=( -gsplit-dwarf )
			BUILD_ARGS+=( use_debug_fission=true )
		else
			RELEASE_EXTRA_CFLAGS+=( -g )
		fi
		BUILD_ARGS+=( symbol_level=2 )
	fi

	use envoy && BUILD_DEFINES+=( envoy=1 )

	# This requires some extreme quoting in order to support multiple flags,
	# e.g. "-gsplit-dwarf -g". This will be deprecated once we switch to gn.
	BUILD_DEFINES+=( "release_extra_cflags=\"'${RELEASE_EXTRA_CFLAGS[*]}'\"" )

	export GYP_GENERATORS="ninja"
	export GYP_DEFINES="${BUILD_DEFINES[*]}"
	export builddir_name="${BUILD_OUT}"
	# Prevents gclient from updating self.
	export DEPOT_TOOLS_UPDATE=0
}

unpack_chrome() {
	local cmd=( "${CHROMITE_BIN_DIR}"/sync_chrome )
	use chrome_internal && cmd+=( --internal )
	if [[ -n "${CROS_SVN_COMMIT}" ]]; then
		cmd+=( --revision="${CROS_SVN_COMMIT}" )
	elif [[ "${CHROME_VERSION}" != "9999" ]]; then
		cmd+=( --tag="${CHROME_VERSION}" )
	fi
	# --reset tells sync_chrome to blow away local changes and to feel
	# free to delete any directories that get in the way of syncing. This
	# is needed for unattended operation.
	cmd+=( --reset --gclient="${EGCLIENT}" "${CHROME_DISTDIR}" )
	elog "${cmd[*]}"
	"${cmd[@]}" || die
}

decide_chrome_origin() {
	local chrome_workon="=chromeos-base/chromeos-chrome-9999"
	local cros_workon_file="${SYSROOT}/etc/portage/package.keywords/cros-workon"
	if [[ -e "${cros_workon_file}" ]] && grep -q "${chrome_workon}" "${cros_workon_file}"; then
		# LOCAL_SOURCE is the default for cros_workon
		# Warn the user if CHROME_ORIGIN is already set
		if [[ -n "${CHROME_ORIGIN}" && "${CHROME_ORIGIN}" != LOCAL_SOURCE ]]; then
			ewarn "CHROME_ORIGIN is already set to ${CHROME_ORIGIN}."
			ewarn "This will prevent you from building from your local checkout."
			ewarn "Please run 'unset CHROME_ORIGIN' to reset Chrome"
			ewarn "to the default source location."
		fi
		: ${CHROME_ORIGIN:=LOCAL_SOURCE}
	else
		# By default, pull from server
		: ${CHROME_ORIGIN:=SERVER_SOURCE}
	fi
}

sandboxless_ensure_directory() {
	local dir
	for dir in "$@"; do
		if [[ ! -d "${dir}" ]] ; then
			# We need root access to create these directories, so we need to
			# use sudo. This implicitly disables the sandbox.
			sudo mkdir -p "${dir}" || die
			sudo chown "${PORTAGE_USERNAME}:portage" "${dir}" || die
			sudo chmod 0755 "${dir}" || die
		fi
	done
}

src_unpack() {
	tc-export CC CXX
	local WHOAMI=$(whoami)
	export EGCLIENT="${EGCLIENT:-/home/${WHOAMI}/depot_tools/gclient}"
	export ENINJA="${ENINJA:-/home/${WHOAMI}/depot_tools/ninja}"
	export DEPOT_TOOLS_UPDATE=0

	# Create storage directories.
	sandboxless_ensure_directory "${CHROME_DISTDIR}" "${CHROME_CACHE_DIR}"

	# Copy in credentials to fake home directory so that build process
	# can access svn and ssh if needed.
	mkdir -p ${HOME}
	SUBVERSION_CONFIG_DIR=/home/${WHOAMI}/.subversion
	if [[ -d ${SUBVERSION_CONFIG_DIR} ]]; then
		cp -rfp ${SUBVERSION_CONFIG_DIR} ${HOME} || die
	fi
	SSH_CONFIG_DIR=/home/${WHOAMI}/.ssh
	if [[ -d ${SSH_CONFIG_DIR} ]]; then
		cp -rfp ${SSH_CONFIG_DIR} ${HOME} || die
	fi
	NET_CONFIG=/home/${WHOAMI}/.netrc
	if [[ -f ${NET_CONFIG} ]]; then
		cp -fp ${NET_CONFIG} ${HOME} || die
	fi
	GITCOOKIES_SRC=/home/${WHOAMI}/.gitcookies
	GITCOOKIES_DST=${HOME}/.gitcookies
	if [[ -f "${GITCOOKIES_SRC}" ]]; then
		cp -fp "${GITCOOKIES_SRC}" "${GITCOOKIES_DST}" || die
		git config --global http.cookiefile "${GITCOOKIES_DST}"
	fi

	decide_chrome_origin

	case "${CHROME_ORIGIN}" in
	LOCAL_SOURCE|SERVER_SOURCE|LOCAL_BINARY)
		elog "CHROME_ORIGIN VALUE is ${CHROME_ORIGIN}"
		;;
	*)
		die "CHROME_ORIGIN not one of LOCAL_SOURCE, SERVER_SOURCE, LOCAL_BINARY"
		;;
	esac

	# Prepare and set CHROME_ROOT based on CHROME_ORIGIN.
	# CHROME_ROOT is the location where the source code is used for compilation.
	# If we're in SERVER_SOURCE mode, CHROME_ROOT is CHROME_DISTDIR. In LOCAL_SOURCE
	# mode, this directory may be set manually to any directory. It may be mounted
	# into the chroot, so it is not safe to use cp -al for these files.
	# These are set here because $(whoami) returns the proper user here,
	# but 'root' at the root level of the file
	case "${CHROME_ORIGIN}" in
	(SERVER_SOURCE)
		elog "Using CHROME_VERSION = ${CHROME_VERSION}"
		if [[ ${WHOAMI} == "chrome-bot" ]]; then
			# TODO: Should add a sanity check that the version checked out is
			# what we actually want.  Not sure how to do that though.
			elog "Skipping syncing as cbuildbot ran SyncChrome for us."
		else
			unpack_chrome
		fi

		elog "set the chrome source root to ${CHROME_DISTDIR}"
		elog "From this point onwards there is no difference between \
			SERVER_SOURCE and LOCAL_SOURCE, since the fetch is done"
		CHROME_ROOT=${CHROME_DISTDIR}
		;;
	(LOCAL_SOURCE)
		: ${CHROME_ROOT:=/home/${WHOAMI}/chrome_root}
		if [[ ! -d "${CHROME_ROOT}/src" ]]; then
			die "${CHROME_ROOT} does not contain a valid chromium checkout!"
		fi
		addwrite "${CHROME_ROOT}"
		;;
	esac

	case "${CHROME_ORIGIN}" in
	LOCAL_SOURCE|SERVER_SOURCE)
		set_build_defines
		;;
	esac

	# FIXME: This is the normal path where ebuild stores its working data.
	# Chrome builds inside distfiles because of speed, so we at least make
	# a symlink here to add compatibility with autotest eclass which uses this.
	ln -sf "${CHROME_ROOT}" "${WORKDIR}/${P}"

	export EGN="${EGN:-${CHROME_ROOT}/src/buildtools/linux64/gn}"
	einfo "Using GN from ${EGN}"

	if use internal_gles_conform; then
		local CHROME_GLES2_CONFORM=${CHROME_ROOT}/src/third_party/gles2_conform
		local CROS_GLES2_CONFORM=/home/${WHOAMI}/trunk/src/third_party/gles2_conform
		if [[ ! -d "${CHROME_GLES2_CONFORM}" ]]; then
			if [[ -d "${CROS_GLES2_CONFORM}" ]]; then
				ln -s "${CROS_GLES2_CONFORM}" "${CHROME_GLES2_CONFORM}"
				einfo "Using GLES2 conformance test suite from ${CROS_GLES2_CONFORM}"
			else
				die "Trying to build GLES2 conformance test suite without ${CHROME_GLES2_CONFORM} or ${CROS_GLES2_CONFORM}"
			fi
		fi
	fi

	if use afdo_use && ! use clang; then
		local PROFILE_DIR="${WORKDIR}/afdo"
		mkdir "${PROFILE_DIR}"
		pushd "${PROFILE_DIR}" > /dev/null

		# First check if there is a specified "frozen" AFDO profile.
		# Otherwise use the current one.
		local PROFILE_FILE="${AFDO_FROZEN_FILE[${ARCH}]}"
		local PROFILE_STATE="FROZEN"
		if [[ -z ${PROFILE_FILE} ]]; then
			PROFILE_FILE="${AFDO_FILE[${ARCH}]}"
			PROFILE_STATE="CURRENT"
		fi
		[[ -n ${PROFILE_FILE} ]] || die "Missing AFDO profile for ${ARCH}"
		unpack "${PROFILE_FILE}${AFDO_BZ_SUFFIX}"
		popd > /dev/null

		AFDO_PROFILE_LOC="${PROFILE_DIR}/${PROFILE_FILE}"
		einfo "Using ${PROFILE_STATE} AFDO data from ${AFDO_PROFILE_LOC}"
	fi
}

add_api_keys() {
	if use gn; then
		# awk script to extract the values out of the file.
		local EXTRACT="{ gsub(/[',]/, \"\", \$2); print \$2 }"
		local api_key=$(awk "/google_api_key/ ${EXTRACT}" "$1")
		local client_id=$(awk "/google_default_client_id/ ${EXTRACT}" "$1")
		local client_secret=$(awk "/google_default_client_secret/ ${EXTRACT}" "$1")

		BUILD_STRING_ARGS+=(
			google_api_key="${api_key}"
			google_default_client_id="${client_id}"
			google_default_client_secret="${client_secret}"
		)
	else
		# RE to match the allowed names.
		local NRE="('google_(api_key|default_client_(id|secret))')"
		# RE to match whitespace.
		local WS="[[:space:]]*"
		# RE to match allowed values.
		local CRE="('[^\\\\']*')"
		# And combining them into one RE for describing the lines
		# we want to allow.
		local TRE="^${WS}${NRE}${WS}[:=]${WS}${CRE}.*"

		mkdir "${HOME}"/.gyp
		cat <<-EOF >"${HOME}/.gyp/include.gypi"
		{
			'variables': {
			$(sed -nr -e "/^${TRE}/{s//\1: \4,/;p;}" "$1")
			}
		}
		EOF
	fi
}
src_prepare() {
	if [[ "${CHROME_ORIGIN}" != "LOCAL_SOURCE" &&
			"${CHROME_ORIGIN}" != "SERVER_SOURCE" ]]; then
		return
	fi

	elog "${CHROME_ROOT} should be set here properly"
	cd "${CHROME_ROOT}/src" || die "Cannot chdir to ${CHROME_ROOT}"

	# We do symlink creation here if appropriate.
	mkdir -p "${CHROME_CACHE_DIR}/src/${BUILD_OUT}"
	if [[ ! -z "${BUILD_OUT_SYM}" ]]; then
		rm -rf "${BUILD_OUT_SYM}" || die "Could not remove symlink"
		ln -sfT "${CHROME_CACHE_DIR}/src/${BUILD_OUT}" "${BUILD_OUT_SYM}" ||
			die "Could not create symlink for output directory"
		export builddir_name="${BUILD_OUT_SYM}"
	fi


	# Apply patches for non-localsource builds.
	if [[ "${CHROME_ORIGIN}" == "SERVER_SOURCE" && ${#PATCHES[@]} -gt 0 ]]; then
		epatch "${PATCHES[@]}"
	fi

	local WHOAMI=$(whoami)
	# The hooks may depend on the environment variables we set in this
	# ebuild (i.e., GYP_DEFINES for gyp_chromium)
	ECHROME_SET_VER=${ECHROME_SET_VER:=/home/${WHOAMI}/trunk/chromite/bin/chrome_set_ver}
	einfo "Building Chrome with the following define options:"
	local opt
	for opt in "${BUILD_DEFINES[@]}"; do
		einfo "${opt}"
	done

	# Get the credentials to fake home directory so that the version of chromium
	# we build can access Google services. First, check for Chrome credentials.
	if [[ ! -d google_apis/internal ]]; then
		# Then look for ChromeOS supplied credentials.
		local PRIVATE_OVERLAYS_DIR=/home/${WHOAMI}/trunk/src/private-overlays
		local GAPI_CONFIG_FILE=${PRIVATE_OVERLAYS_DIR}/chromeos-overlay/googleapikeys
		if [[ ! -f "${GAPI_CONFIG_FILE}" ]]; then
			# Then developer credentials.
			GAPI_CONFIG_FILE=/home/${WHOAMI}/.googleapikeys
		fi
		if [[ -f "${GAPI_CONFIG_FILE}" ]]; then
			add_api_keys "${GAPI_CONFIG_FILE}"
		fi
	fi
}

setup_test_lists() {
	TEST_FILES=(
		media_unittests
		sandbox_linux_unittests
		video_decode_accelerator_unittest
		video_encode_accelerator_unittest
	)

	if use gn; then
		TEST_FILES+=( ppapi/examples/video_decode )
	else
		TEST_FILES+=( ppapi_example_video_decode )
		# TODO(ihf/stevenjb/kbr): Investigate why these targets fail with GN.
		# crbug.com/609958
		if use chrome_internal || use internal_gles_conform; then
			TEST_FILES+=( gles2_conform_test{,_windowless} )
		fi
	fi

	# TODO(ihf): Figure out how to keep this in sync with telemetry.
	TOOLS_TELEMETRY_BIN=(
		bitmaptools
		clear_system_cache
		minidump_stackwalk
	)

	PPAPI_TEST_FILES=(
		lib{32,64}
		mock_nacl_gdb
		ppapi_nacl_tests_{newlib,glibc}.nmf
		ppapi_nacl_tests_{newlib,glibc}_{x32,x64,arm}.nexe
		test_case.html
		test_case.html.mock-http-headers
		test_page.css
		test_url_loader_data
	)
}

# Handle all CFLAGS/CXXFLAGS/etc... munging here.
setup_compile_flags() {
	# The chrome makefiles specify -O and -g flags already, so remove the
	# portage flags.
	filter-flags -g -O*

	# -clang-syntax is a flag that enable us to do clang syntax checking on
	# top of building Chrome with gcc. Since Chrome itself is clang clean,
	# there is no need to check it again in ChromeOS land. And this flag has
	# nothing to do with USE=clang.
	filter-flags -clang-syntax

	# There are some flags we want to only use in the ebuild.
	# The rest will be exported to the simple chrome workflow.
	EBUILD_CFLAGS=()
	EBUILD_CXXFLAGS=()
	if use afdo_use && ! use clang; then
		local afdo_flags=(
			-fauto-profile="${AFDO_PROFILE_LOC}"

			# This is required because gcc emits different warnings
			# for AFDO vs. non-AFDO. AFDO may inline different
			# functions from non-AFDO, leading to different warnings.
			-Wno-error
		)
		EBUILD_CFLAGS+=( "${afdo_flags[@]}" )
		EBUILD_CXXFLAGS+=( "${afdo_flags[@]}" )
	fi

	# The .dwp file for x86 and arm exceeds 4GB limit. Adding this flag as a
	# workaround. The generated symbol files are the same with/without this
	# flag. See https://crbug.com/641188
	if use chrome_debug && ( use x86 || use arm ) && ! use clang; then
		EBUILD_CFLAGS+=( -femit-struct-debug-reduced )
		EBUILD_CXXFLAGS+=( -femit-struct-debug-reduced )
	fi

	# Enable std::vector []-operator bounds checking.
	append-cxxflags -D__google_stl_debug_vector=1

	# Chrome and ChromeOS versions of the compiler may not be in
	# sync. So, don't complain if Chrome uses a diagnostic
	# option that is not yet implemented in the compiler version used
	# by ChromeOS.
	# Turns out this is only really supported by Clang. See crosbug.com/615466
	if use clang; then
		append-flags -Wno-unknown-warning-option
		export CXXFLAGS_host+=" -Wno-unknown-warning-option"
		export CFLAGS_host+=" -Wno-unknown-warning-option"
	fi

	# crbug.com/532532
	filter-flags "-Wl,--fix-cortex-a53-843419"

	use vtable_verify && append-ldflags -fvtable-verify=preinit

	local flags
	einfo "Building with the compiler settings:"
	for flags in {C,CXX,CPP,LD}FLAGS; do
		einfo "  ${flags} = ${!flags}"
	done
}

src_configure() {
	clang-setup-env
	# Chrome handles sanitizer flags by itself; so the '-fsanitize=*' flag added
	# by clang-setup-env is not needed. -- crbug.com/425390
	filter-flags "-fsanitize=*"
	tc-export CXX CC AR AS RANLIB STRIP
	export CC_host=$(usex clang "clang" "$(tc-getBUILD_CC)")
	export CXX_host=$(usex clang "clang++" "$(tc-getBUILD_CXX)")
	export AR_host=$(tc-getBUILD_AR)
	if use gold ; then
		if [[ "${GOLD_SET}" != "yes" ]]; then
			export GOLD_SET="yes"
			einfo "Using gold from the following location: $(get_binutils_path_gold)"
			export CC="${CC} -B$(get_binutils_path_gold)"
			export CXX="${CXX} -B$(get_binutils_path_gold)"
		fi
	else
		ewarn "gold disabled. Using GNU ld."
	fi

	# Use g++ as the linker driver.
	export LD="${CXX}"
	export LD_host=$(tc-getBUILD_CXX)

	setup_compile_flags

	local build_tool_flags=(
		"config=${BUILDTYPE}"
		"output_dir=${builddir_name}"
	)
	export GYP_GENERATOR_FLAGS="${build_tool_flags[*]}"
	export BOTO_CONFIG=/home/$(whoami)/.boto
	export PATH=${PATH}:/home/$(whoami)/depot_tools

	export DEPOT_TOOLS_GSUTIL_BIN_DIR="${CHROME_CACHE_DIR}/gsutil_bin"

	# TODO(rcui): crosbug.com/20435. Investigate removal of runhooks
	# useflag when chrome build switches to Ninja inside the chroot.
	if use runhooks; then
		[[ -f "${EGCLIENT}" ]] || die "EGCLIENT at '${EGCLIENT}' does not exist"
		local cmd=( "${EGCLIENT}" runhooks --force )
		echo "${cmd[@]}"
		CFLAGS="${CFLAGS} ${EBUILD_CFLAGS[*]}" \
		CXXFLAGS="${CXXFLAGS} ${EBUILD_CXXFLAGS[*]}" \
		GYP_CHROMIUM_NO_ACTION=$(use10 gn) \
		"${cmd[@]}" || die
	fi

	BUILD_STRING_ARGS+=(
		cros_target_ar="${AR}"
		cros_target_cc="${CC}"
		cros_target_cxx="${CXX}"
		host_toolchain="//build/toolchain/cros:host"
		custom_toolchain="//build/toolchain/cros:target"
		v8_snapshot_toolchain="//build/toolchain/cros:v8_snapshot"
		cros_target_ld="${LD}"
		cros_target_extra_cflags="${CFLAGS} ${EBUILD_CFLAGS[*]}"
		cros_target_extra_cppflags="${CPPFLAGS}"
		cros_target_extra_cxxflags="${CXXFLAGS} ${EBUILD_CXXFLAGS[*]}"
		cros_target_extra_ldflags="${LDFLAGS}"
		cros_host_cc="${CC_host}"
		cros_host_cxx="${CXX_host}"
		cros_host_ar="${AR_host}"
		cros_host_ld="${LD_host}"
		cros_host_extra_cflags="${CFLAGS_host}"
		cros_host_extra_cxxflags="${CXXFLAGS_host}"
		cros_host_extra_cppflags="${CPPFLAGS_host}"
		cros_host_extra_ldflags="${LDFLAGS_host}"
		cros_v8_snapshot_cc="${CC_host}"
		cros_v8_snapshot_cxx="${CXX_host}"
		cros_v8_snapshot_ar="${AR_host}"
		cros_v8_snapshot_ld="${LD_host}"
		cros_v8_snapshot_extra_cflags="${CFLAGS_host}"
		cros_v8_snapshot_extra_cxxflags="${CXXFLAGS_host}"
		cros_v8_snapshot_extra_cppflags="${CPPFLAGS_host}"
		cros_v8_snapshot_extra_ldflags="${LDFLAGS_host}"
	)

	local arg
	for arg in "${BUILD_STRING_ARGS[@]}"; do
		BUILD_ARGS+=("${arg%%=*}=\"${arg#*=}\"")
	done
	export GN_ARGS="${BUILD_ARGS[*]}"
	if use gn; then
		einfo "GN_ARGS = ${GN_ARGS}"
		${EGN} gen "${CHROME_ROOT}/src/${BUILD_OUT_SYM}/${BUILDTYPE}" \
			--args="${GN_ARGS}" --root="${CHROME_ROOT}/src" || die
	fi

	setup_test_lists
}

chrome_make() {
	PATH=${PATH}:/home/$(whoami)/depot_tools ${ENINJA} \
		${MAKEOPTS} -C "${BUILD_OUT_SYM}/${BUILDTYPE}" $(usex verbose -v "") "$@" || die
}

src_compile() {
	if [[ "${CHROME_ORIGIN}" != "LOCAL_SOURCE" &&
			"${CHROME_ORIGIN}" != "SERVER_SOURCE" ]]; then
		return
	fi

	cd "${CHROME_ROOT}"/src || die "Cannot chdir to ${CHROME_ROOT}/src"

	local chrome_targets=(
		chrome_sandbox
		libosmesa.so
		$(usex mojo "mojo_shell" "")
	)
	# Envoy builds set both the envoy and app_shell USE flags; only build the
	# envoy_shell binary in this case.
	if use envoy; then
		chrome_targets+=( envoy_shell )
	elif use app_shell; then
		chrome_targets+=( app_shell )
	else
		chrome_targets+=( chrome )
	fi
	if use build_tests; then
		chrome_targets+=(
			"${TEST_FILES[@]}"
			"${TOOLS_TELEMETRY_BIN[@]}"
			chromedriver
		)
	fi
	use_nacl && chrome_targets+=( nacl_helper_bootstrap nacl_helper )

	chrome_make "${chrome_targets[@]}"

	if use build_tests; then
		install_chrome_test_resources "${WORKDIR}/test_src"
		install_page_cycler_dep_resources "${WORKDIR}/page_cycler_src"
		install_perf_data_dep_resources "${WORKDIR}/perf_data_src"
		install_telemetry_dep_resources "${WORKDIR}/telemetry_src"

		# NOTE: Since chrome is built inside distfiles, we have to get
		# rid of the previous instance first.
		# We remove only what we will overwrite with the mv below.
		local deps="${WORKDIR}/${P}/${AUTOTEST_DEPS}"

		rm -rf "${deps}/chrome_test/test_src"
		mv "${WORKDIR}/test_src" "${deps}/chrome_test/"

		rm -rf "${deps}/page_cycler_dep/test_src"
		mv "${WORKDIR}/page_cycler_src" "${deps}/page_cycler_dep/test_src"

		rm -rf "${deps}/perf_data_dep/test_src"
		mv "${WORKDIR}/perf_data_src" "${deps}/perf_data_dep/test_src"

		rm -rf "${deps}/telemetry_dep/test_src"
		mv "${WORKDIR}/telemetry_src" "${deps}/telemetry_dep/test_src"

		# HACK: It would make more sense to call autotest_src_prepare in
		# src_prepare, but we need to call install_chrome_test_resources first.
		autotest-deponly_src_prepare

		# Remove .svn dirs
		esvn_clean "${AUTOTEST_WORKDIR}"
		# Remove .git dirs
		find "${AUTOTEST_WORKDIR}" -type d -name .git -prune -exec rm -rf {} +

		autotest_src_compile
	fi
}

# Turn off the cp -l behavior in autotest, since the source dir and the
# installation dir live on different bind mounts right now.
fast_cp() {
	cp "$@"
}

install_test_resources() {
	# Install test resources from chrome source directory to destination.
	# We keep a cache of test resources inside the chroot to avoid copying
	# multiple times.
	local test_dir="${1}"
	einfo "install_test_resources to ${test_dir}"
	shift

	# To speed things up, we write the list of files to a temporary file so
	# we can use rsync with --files-from.
	local tmp_list_file="${T}/${test_dir##*/}.files"
	printf "%s\n" "$@" > "${tmp_list_file}"

	# Copy the specific files to the cache from the source directory.
	# Note: we need to specify -r when using --files-from and -a to get a
	# recursive copy.
	# TODO(ihf): Make failures here fatal.
	rsync -r -a --delete --exclude=.svn --exclude=.git --exclude="*.pyc" \
		--files-from="${tmp_list_file}" "${CHROME_ROOT}/src/" \
		"${CHROME_CACHE_DIR}/src/"

	# Create hard links in the destination based on the cache.
	# Note: we need to specify -r when using --files-from and -a to get a
	# recursive copy.
	# TODO(ihf): Make failures here fatal.
	rsync -r -a --link-dest="${CHROME_CACHE_DIR}/src" \
		--files-from="${tmp_list_file}" "${CHROME_CACHE_DIR}/src/" "${test_dir}/"
}

test_strip_install() {
	local from="${1}"
	local dest="${2}"
	shift 2
	mkdir -p "${dest}"
	local f
	for f in "$@"; do
		$(tc-getSTRIP) --strip-debug --keep-file-symbols \
			"${from}"/${f} -o "${dest}/$(basename ${f})"
	done
}

install_chrome_test_resources() {
	# NOTE: This is a duplicate from src_install, because it's required here.
	local from="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"
	local test_dir="${1}"
	local dest="${test_dir}/out/Release"

	echo Copying Chrome tests into "${test_dir}"

	# Even if chrome_debug_tests is enabled, we don't need to include detailed
	# debug info for tests in the binary package, so save some time by stripping
	# everything but the symbol names. Developers who need more detailed debug
	# info on the tests can use the original unstripped tests from the ${from}
	# directory.
	TEST_INSTALL_TARGETS=(
		"${TEST_FILES[@]}"
		"libppapi_tests.so"
		"chrome_sandbox" )

	einfo "Installing test targets: ${TEST_INSTALL_TARGETS[@]}"
	test_strip_install "${from}" "${dest}" "${TEST_INSTALL_TARGETS[@]}"

	# Copy Chrome test data.
	mkdir -p "${dest}"/test_data
	# WARNING: Only copy subdirectories of |test_data|.
	# The full |test_data| directory is huge and kills our VMs.
	# Example:
	# cp -al "${from}"/test_data/<subdir> "${test_dir}"/out/Release/<subdir>

	# Add the fake bidi locale.
	mkdir -p "${dest}"/pseudo_locales
	cp -al "${from}"/pseudo_locales/fake-bidi.pak \
		"${dest}"/pseudo_locales

	for f in "${PPAPI_TEST_FILES[@]}"; do
		cp -al "${from}/${f}" "${dest}"
	done

	# Install Chrome test resources.
	# WARNING: Only install subdirectories of |chrome/test|.
	# The full |chrome/test| directory is huge and kills our VMs.
	install_test_resources "${test_dir}" \
		base/base_paths_posix.cc \
		chrome/test/data/chromeos \
		chrome/test/functional \
		chrome/third_party/mock4js/mock4js.js  \
		content/common/gpu/testdata \
		media/test/data \
		content/test/data \
		net/data/ssl/certificates \
		ppapi/tests/test_case.html \
		ppapi/tests/test_url_loader_data \
		third_party/bidichecker/bidichecker_packaged.js \
		third_party/accessibility-developer-tools/gen/axs_testing.js

	# Add the pdf test data if needed.
	if use chrome_internal; then
		install_test_resources "${test_dir}" pdf/test
	fi
	# Add the gles_conform test data if needed.
	if use chrome_internal || use internal_gles_conform; then
		install_test_resources "${test_dir}" gpu/gles2_conform_support/gles2_conform_test_expectations.txt
	fi

	cp -a "${CHROME_ROOT}"/"${AUTOTEST_DEPS}"/chrome_test/setup_test_links.sh \
		"${dest}"
}

install_page_cycler_dep_resources() {
	local test_dir="${1}"

	if [[ -r "${CHROME_ROOT}/src/data/page_cycler" ]]; then
		echo "Copying Page Cycler Data into ${test_dir}"
		mkdir -p "${test_dir}"
		install_test_resources "${test_dir}" \
			data/page_cycler
	fi
}

install_perf_data_dep_resources() {
	local test_dir="${1}"

	if [[ -r "${CHROME_ROOT}/src/tools/perf/data" ]]; then
		echo "Copying Perf Data into ${test_dir}"
		mkdir -p "${test_dir}"
		install_test_resources "${test_dir}" tools/perf/data
	fi
}

install_telemetry_dep_resources() {
	local test_dir="${1}"

	TELEMETRY=${CHROME_ROOT}/src/third_party/catapult/telemetry
	if [[ -r "${TELEMETRY}" ]]; then
		echo "Copying Telemetry Framework into ${test_dir}"
		mkdir -p "${test_dir}"
		# We are going to call chromium code but can't trust that it is clean
		# of precompiled code. See crbug.com/590762.
		find "${TELEMETRY}" -name "*.pyc" -type f -delete
		# Get deps from Chrome.
		FIND_DEPS=${CHROME_ROOT}/src/tools/perf/find_dependencies
		PERF_DEPS=${CHROME_ROOT}/src/tools/perf/bootstrap_deps
		CROS_DEPS=${CHROME_ROOT}/src/tools/cros/bootstrap_deps
		# sed removes the leading path including src/ converting it to relative.
		# To avoid silent failures assert the success.
		DEPS_LIST=$(python ${FIND_DEPS} ${PERF_DEPS} ${CROS_DEPS} | \
			sed -e 's|^'${CHROME_ROOT}/src/'||'; assert)
		install_test_resources "${test_dir}" "${DEPS_LIST}" \
			chrome/test/data/image_decoding \
			content/test/data/gpu \
			content/test/data/media \
			content/test/gpu
		# For crosperf, which uses some tests only available on internal builds.
		if use chrome_internal; then
			install_test_resources "${test_dir}" \
				data/page_cycler/morejs \
				data/page_cycler/moz
		fi
	fi

	local from="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"
	local dest="${test_dir}/src/out/${BUILDTYPE}"
	einfo "Installing telemetry binaries: ${TOOLS_TELEMETRY_BIN[@]}"
	test_strip_install "${from}" "${dest}" "${TOOLS_TELEMETRY_BIN[@]}"

	# When copying only a portion of the Chrome source that telemetry needs,
	# some symlinks can end up broken. Thus clean these up before packaging.
	find -L "${test_dir}" -type l -delete
}

# Add any new artifacts generated by the Chrome build targets to deploy_chrome.py.
# We deal with miscellaneous artifacts here in the ebuild.
src_install() {
	FROM="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"

	# Override default strip flags and lose the '-R .comment'
	# in order to play nice with the crash server.
	if [[ -z "${KEEP_CHROME_DEBUG_SYMBOLS}" ]]; then
		export PORTAGE_STRIP_FLAGS="--strip-unneeded"
	else
		export PORTAGE_STRIP_FLAGS="--strip-debug --keep-file-symbols"
	fi
	# TODO(ihf): Remove this once 595763 is fixed.
	eerror "PORTAGE_STRIP_FLAGS=${PORTAGE_STRIP_FLAGS}"
	LS=$(ls -alhS ${FROM})
	eerror "CHROME_DIR after build\n${LS}"

	# Copy org.chromium.LibCrosService.conf, the D-Bus config file for the
	# D-Bus service exported by Chrome.
	insinto /etc/dbus-1/system.d
	DBUS="${CHROME_ROOT}"/src/chromeos/dbus/services
	doins "${DBUS}"/org.chromium.LibCrosService.conf

	# Copy Quickoffice resources for official build.
	if use chrome_internal; then
		insinto /usr/share/chromeos-assets/quickoffice
		QUICKOFFICE="${CHROME_ROOT}"/src/chrome/browser/resources/chromeos/quickoffice
		doins -r "${QUICKOFFICE}"/_locales
		doins -r "${QUICKOFFICE}"/css
		doins -r "${QUICKOFFICE}"/img
		doins -r "${QUICKOFFICE}"/plugin
		doins -r "${QUICKOFFICE}"/scripts
		doins -r "${QUICKOFFICE}"/views

		insinto /usr/share/chromeos-assets/quickoffice/_platform_specific
		case "${ARCH}" in
		arm)
			doins -r "${QUICKOFFICE}"/_platform_specific/arm
			;;
		x86)
			doins -r "${QUICKOFFICE}"/_platform_specific/x86_32
			;;
		amd64)
			doins -r "${QUICKOFFICE}"/_platform_specific/x86_64
			;;
		*)
			die "Unsupported architecture: ${ARCH}"
			;;
		esac
	fi

	# Chrome test resources
	# Test binaries are only available when building chrome from source
	if use build_tests && [[ "${CHROME_ORIGIN}" == "LOCAL_SOURCE" ||
		"${CHROME_ORIGIN}" == "SERVER_SOURCE" ]]; then
		autotest-deponly_src_install
		#env -uRESTRICT prepstrip "${D}${AUTOTEST_BASE}"

		# Copy input_methods.txt for auto-test.
		insinto /usr/share/chromeos-assets/input_methods
		doins "${CHROME_ROOT}"/src/chromeos/ime/input_methods.txt

		# Copy generated cloud_policy.proto. We can't do this in the
		# protofiles ebuild since this is a generated proto.
		insinto /usr/share/protofiles
		# stevenjb: It is unclear why the .proto is in gen/policy/policy
		# in GYP and gen/policy/ in GN, but once we move away from GYP
		# that shouldn't matter.
		# TODO(nya): Remove old paths once they are no longer used.
		# See: crbug.com/640896
		if [[ -f "${FROM}"/gen/components/policy/proto/cloud_policy.proto ]]; then
			doins "${FROM}"/gen/components/policy/proto/cloud_policy.proto
		elif use gn; then
			doins "${FROM}"/gen/policy/cloud_policy.proto
		else
			doins "${FROM}"/gen/policy/policy/cloud_policy.proto
		fi
	fi

	# Fix some perms.
	# TODO(rcui): Remove this - shouldn't be needed, and is just covering up
	# potential permissions bugs.
	chmod -R a+r "${D}"
	find "${D}" -perm /111 -print0 | xargs -0 chmod a+x

	# The following symlinks are needed in order to run chrome.
	# TODO(rcui): Remove this.  Not needed for running Chrome.
	dosym libnss3.so /usr/lib/libnss3.so.1d
	dosym libnssutil3.so.12 /usr/lib/libnssutil3.so.1d
	dosym libsmime3.so.12 /usr/lib/libsmime3.so.1d
	dosym libssl3.so.12 /usr/lib/libssl3.so.1d
	dosym libplds4.so /usr/lib/libplds4.so.0d
	dosym libplc4.so /usr/lib/libplc4.so.0d
	dosym libnspr4.so /usr/lib/libnspr4.so.0d

	# Create the main Chrome install directory.
	dodir "${CHROME_DIR}"
	insinto "${CHROME_DIR}"

	# Enable the chromeos local account, if the environment dictates.
	if [[ -n "${CHROMEOS_LOCAL_ACCOUNT}" ]]; then
		echo "${CHROMEOS_LOCAL_ACCOUNT}" > "${T}/localaccount"
		doins "${T}/localaccount"
	fi

	# Use the deploy_chrome from the *Chrome* checkout.  The benefit of
	# doing this is if a new buildspec of Chrome requires a non-backwards
	# compatible change to deploy_chrome, we can commit the fix to
	# deploy_chrome without breaking existing Chrome OS release builds,
	# and then roll the DEPS for chromite in the Chrome checkout.
	#
	# Another benefit is each version of Chrome will have the right
	# corresponding version of deploy_chrome.
	local cmd=( "${CHROME_ROOT}"/src/third_party/chromite/bin/deploy_chrome )
	# Disable stripping for now, as deploy_chrome doesn't generate splitdebug files.
	cmd+=(
		--board="${BOARD}"
		--build-dir="${FROM}"
		--gyp-defines="${GYP_DEFINES}"
		--gn-args="${GN_ARGS}"
		# If this is enabled, we need to re-enable `prepstrip` above for autotests.
		# You'll also have to re-add "strip" to the RESTRICT at the top of the file.
		--nostrip
		--staging-dir="${D_CHROME_DIR}"
		--staging-flags="${USE}"
		--staging-only
		--strict
		--strip-bin="${STRIP}"
		--strip-flags="${PORTAGE_STRIP_FLAGS}"
		--verbose
	)
	# TODO(ihf): Make this einfo again once 595763 is fixed.
	eerror "${cmd[*]}"
	"${cmd[@]}" || die
	LS=$(ls -alhS ${D}/${CHROME_DIR})
	eerror "CHROME_DIR after deploy_chrome\n${LS}"

	# Keep the .dwp file.
	if use chrome_debug && ( use x86 || use arm ); then
		mkdir -p "${D}/usr/lib/debug/${CHROME_DIR}"
		DWP="${CHOST}"-dwp
		cd "${D}/${CHROME_DIR}"
		# Iterate over all ELF files in current directory
		while read i; do
			cd "${FROM}"
			# There two files does not build with -gsplit-dwarf,
			# so we do not need to get .dwp file from them.
			if [[ "${i}" == "./nacl_helper_nonsfi" ]] ||
				[[ "${i}" == "./nacl_irt_x86_32.nexe" ]] ; then
				continue
			fi
			source="${i}"
			# The chrome_sandbox is renamed to chrome_sandbox.
			# Use the original file to generate the .dwp file.
			if [[ ${source} == "./chrome-sandbox" ]] ; then
				source="chrome_sandbox"
			fi
			${DWP} -e "${FROM}/${source}" -o "${D}/usr/lib/debug/${CHROME_DIR}/${i}.dwp"
		done < <(scanelf -BRyF '%F' ".")
	fi

	if use build_tests; then
		# Install Chrome Driver to test image.
		local chromedriver_dir='/usr/local/chromedriver'
		dodir "${chromedriver_dir}"
		cp -pPR "${FROM}"/chromedriver "${D}/${chromedriver_dir}" || die
	fi
}

pkg_preinst() {
	enewuser "wayland"
	enewgroup "wayland"
}

pkg_postinst() {
	autotest_pkg_postinst
	LS=$(ls -alhS ${ROOT}/${CHROME_DIR})
	eerror "CHROME_DIR after installation\n${LS}"
	CHROME_SIZE=$(stat --printf="%s" ${ROOT}/${CHROME_DIR}/chrome)
	eerror "CHROME_SIZE = ${CHROME_SIZE}"
	if [[ ${CHROME_SIZE} -ge 200000000 && -z "${KEEP_CHROME_DEBUG_SYMBOLS}" ]]; then
		die "Installed chrome binary got suspiciously large (size=${CHROME_SIZE})."
	fi
}
