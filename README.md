<!-- cSpell:ignore brcm, realtek -->

# ChromiumOS

Chromium OS is an open-source project that aims to build an operating system that provides a fast, simple, and more secure computing experience for people who spend most of their time on the web.

This repo is for the special builds only

All downloads are located at <http://chromium.arnoldthebat.co.uk/>.

Clone this repo to your overlay name in your repo/src/overlays

## Alpha Builds

### Known Issues

* Play Store does not work.
* The Google assistant does not work.
* "This is the last automatic software and security upgrade statement" can safely be ignored since this wont prevent subsequent updates.

### Change Log 29/09/19

* Realtek rtl8192e wireless support
* Realtek rtl8712  wireless support
* Realtek rtl8723bs wireless support
* Additional SOC sound card support

### Change Log - 17/09/19

* Realtek rtl8188EU Wireless support
* Added in MediaTek MT7601U support
* Added in various Ethernet drivers support

### Change Log - 08/09/19

* Added in all 4.14 kernel supported Marvell Wireless cards
* Switched back to Intel IWL7K Wireless drivers
* Added in brcm80211 drivers and removed old BroadCom STA driver
