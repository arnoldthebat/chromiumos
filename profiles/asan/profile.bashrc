#!/bin/bash
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

case "${PN}" in
	"chromeos-chrome")
		# We want to be able to easily symbolize possible asan failure logs.
                export KEEP_CHROME_DEBUG_SYMBOLS=1
		;;
esac
