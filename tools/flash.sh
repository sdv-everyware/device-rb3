#!/usr/bin/env bash
# Flashes the built images onto the RB3. The board has to be in the bootloader's fastboot
# mode (adb reboot bootloader, or VOL- held while powering on).
#
#     tools/flash.sh images    boot, vendor_boot and super; userdata and metadata stay
#     tools/flash.sh all       Linaro's flash-all-aosp.sh: also the bootloader partitions,
#                              and it wipes userdata and metadata
#
# There is no fastbootd on this board (Linaro's db845c has no recovery), so the logical
# partitions cannot be flashed one by one: a change in system, vendor or product is the
# whole super.img.
set -euo pipefail

mode="${1:-}"
case "$mode" in images|all) ;; *) sed -n '2,11p' "$0"; exit 2 ;; esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$HERE/env.sh" >/dev/null
: "${ANDROID_BUILD_TOP:?lunch did not set ANDROID_BUILD_TOP}"
: "${ANDROID_PRODUCT_OUT:?lunch did not set ANDROID_PRODUCT_OUT}"
export ANDROID_BUILD_TOP ANDROID_PRODUCT_OUT

for img in boot.img vendor_boot.img super.img; do
  [ -s "$ANDROID_PRODUCT_OUT/$img" ] || { echo "missing $ANDROID_PRODUCT_OUT/$img: build first (m)"; exit 1; }
done

FASTBOOT="${FASTBOOT:-$ANDROID_BUILD_TOP/$OUT_DIR/host/linux-x86/bin/fastboot}"
[ -x "$FASTBOOT" ] || FASTBOOT="$(command -v fastboot)"
export PATH="$(dirname "$FASTBOOT"):$PATH"

if ! fastboot devices | grep -q fastboot; then
  echo "no device in fastboot mode"; exit 1
fi
fastboot devices

if [ "$mode" = images ]; then
  fastboot flash boot "$ANDROID_PRODUCT_OUT/boot.img"
  fastboot flash vendor_boot "$ANDROID_PRODUCT_OUT/vendor_boot.img"
  fastboot flash super "$ANDROID_PRODUCT_OUT/super.img"
  fastboot reboot
  exit 0
fi

echo "this reflashes the bootloader, boot, vendor_boot and super, and wipes userdata and metadata"
read -r -p "continue? [y/N] " ans
[ "$ans" = "y" ] || { echo "aborted"; exit 1; }
cd "$ANDROID_BUILD_TOP/device/linaro/dragonboard/installer/db845c"
exec ./flash-all-aosp.sh
