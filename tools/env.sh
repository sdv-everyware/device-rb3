#!/usr/bin/env bash
# Build environment for sdv_media_db845c. Source it, do not execute it: lunch and OUT_DIR
# have to land in the calling shell.
#
#     source device/rb3/sdv_media_db845c/tools/env.sh
#     m
#
# OUT_DIR is out_rb3, one out directory for this product: a product switch inside a shared
# out directory rebuilds thousands of steps. Set RB3_OUT_DISK to a mount point to keep the
# directory on another disk; the tree then gets a symlink to it (Soong rejects an absolute
# out directory outside the tree).
#
# Needs the Linaro vendor package (firmware) in vendor/linaro:
#     device/linaro/dragonboard/vendor-package-ver.sh url

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "source me, do not execute: source ${0}"
  exit 1
fi

TREE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export OUT_DIR="${OUT_DIR:-out_rb3}"

if [ -n "${RB3_OUT_DISK:-}" ]; then
  if ! mountpoint -q "$RB3_OUT_DISK"; then
    echo "RB3_OUT_DISK=$RB3_OUT_DISK is not a mount point. Not sourcing."
    return 1
  fi
  if [ -e "$TREE/$OUT_DIR" ] && [ ! -L "$TREE/$OUT_DIR" ]; then
    echo "$TREE/$OUT_DIR exists and is not a symlink. Not sourcing."
    return 1
  fi
  mkdir -p "$RB3_OUT_DISK/$OUT_DIR"
  [ -L "$TREE/$OUT_DIR" ] || ln -s "$RB3_OUT_DISK/$OUT_DIR" "$TREE/$OUT_DIR"
fi

VENDOR_VER="$("$TREE/device/linaro/dragonboard/vendor-package-ver.sh" ver)"
if [ ! -d "$TREE/vendor/linaro/db845c/$VENDOR_VER" ]; then
  echo "vendor/linaro/db845c/$VENDOR_VER is missing (the Linaro firmware package)."
  echo "Download: $("$TREE/device/linaro/dragonboard/vendor-package-ver.sh" url)"
  echo "Extract it in $TREE (it creates vendor/linaro/...). Not sourcing."
  return 1
fi

cd "$TREE" || return 1
source build/envsetup.sh
lunch sdv_media_db845c-trunk_staging-userdebug || return 1
echo "OUT_DIR=$OUT_DIR  vendor package $VENDOR_VER"
