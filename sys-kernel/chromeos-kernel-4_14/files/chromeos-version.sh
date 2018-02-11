#!/bin/bash
#
# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is given one argument: the base of the source directory of
# the package, and it prints a string on stdout with the numerical version
# number for said repo.

# Matching regexp for all known kernel release tags to date.
GLOB="v[2-9].*[0-9]"
PATTERN="^v[2-9](\.[0-9]+)+(-rc[0-9]+)?$"

if [ ! -d "$1" ] ; then
    exit
fi

cd "$1" || exit

# If the script runs from a board overlay, add "_p1" to returned kernel version.
SCRIPT=$(realpath "$0")
OVERLAY_ROOT="$(dirname "${SCRIPT}")/../../.."
OVERLAY_NAME=$(sed -n '/^repo-name *=/s:[^=]*= *::p' "${OVERLAY_ROOT}"/metadata/layout.conf)

suffix=""
if [[ "${OVERLAY_NAME}" != "chromiumos" ]]; then
    suffix="_p1"
fi

version=$(git describe --match "${GLOB}" --abbrev=0 HEAD | egrep "${PATTERN}" |
  sed s/v\\.*//g | sed s/-/_/g)

if [[ -n "${version}" ]]; then
    echo "${version}${suffix}"
fi
