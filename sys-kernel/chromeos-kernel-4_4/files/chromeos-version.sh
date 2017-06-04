#!/bin/sh
#
# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is given one argument: the base of the source directory of
# the package, and it prints a string on stdout with the numerical version
# number for said repo.

# Matching regexp for all known kernel release tags to date.
PATTERN="v[234].*"

if [ ! -d "$1" ] ; then
    exit
fi

cd "$1" || exit

# Hack around known bad tag https://crbug.com/653672
git tag -d "v4.4.21-baseline" >/dev/null 2>&1 || :

git describe --match "${PATTERN}" --abbrev=0 HEAD | egrep "${PATTERN}" |
  sed s/v\\.*//g | sed s/-/_/g
