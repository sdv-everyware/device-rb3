# Linaro's board config first (it sets TARGET_BOARD_PLATFORM, which keys kernel, dtb, fstab and
# sepolicy of the board), then the SDV pieces.

include device/linaro/dragonboard/db845c/BoardConfig.mk

# only errors on the 115200 baud serial console: every printed line costs 7 ms of boot
BOARD_KERNEL_CMDLINE += loglevel=4

BOARD_SEPOLICY_DIRS += device/google/sdv/sdv_core_base/sepolicy/vendor/

BOARD_VENDOR_SEPOLICY_DIRS += device/rb3/sdv_media_db845c/sepolicy/vendor

# the root init: init reads this file and its imports only. Every bootconfig key once across
# this file and vendor_boot, or the kernel drops the whole bootconfig. Permissive while the
# denials of the board are collected.
BOARD_BOOTCONFIG += \
    androidboot.init_rc=/system/etc/init/hw/init.sdv_media.rc \
    androidboot.adb.enabled=1 \
    androidboot.selinux=permissive

# kernel modules: Linaro loads all 324 in first stage (10.7 s of the boot). Here first stage
# gets Linaro's first-stage list plus what the disk and the display need; the rest goes to
# vendor_dlkm, loaded in the background. No test modules, no VM-only drivers (they fail, and
# dlkm_loader stops at the first failure).
RB3_KERNEL_DIR := device/linaro/dragonboard-kernel/android-6.12
include device/linaro/dragonboard/shared/utils/dlkm_loader/vendor.modules.list.mk
RB3_KERNEL_MODULES := $(wildcard $(RB3_KERNEL_DIR)/*.ko)
# the UFS driver (a module in 6.12) and what it needs: without them first stage sees no disk
RB3_FIRST_STAGE_STORAGE_MODULES := \
    ufs-qcom.ko qcom_ice.ko qcom_tzmem.ko phy-qcom-qmp-ufs.ko \
    qcom_spmi-regulator.ko nvmem_qfprom.ko icc-clk.ko
# dependencies of Linaro's list that 6.12 split out (modinfo); a missing one panics the kernel
RB3_FIRST_STAGE_DEPENDENCY_MODULES := \
    qcom_pdr_msg.ko snd-q6dsp-common.ko snd-soc-lpass-macro-common.ko \
    snd-soc-qcom-sdw.ko snd-soc-wcd-classh.ko
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := \
    $(patsubst %,$(RB3_KERNEL_DIR)/%,$(VENDOR_RAMDISK_KERNEL_MODULES_LIST) \
        $(RB3_FIRST_STAGE_STORAGE_MODULES) $(RB3_FIRST_STAGE_DEPENDENCY_MODULES))
BOARD_SYSTEM_KERNEL_MODULES := \
    $(wildcard $(RB3_KERNEL_DIR)/btqca.ko) \
    $(wildcard $(RB3_KERNEL_DIR)/hci_uart.ko) \
    $(wildcard $(RB3_KERNEL_DIR)/rfcomm.ko)
# stripping removes the module signatures, and the GKI kernel refuses unsigned GKI modules
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
BOARD_DO_NOT_STRIP_SYSTEM_MODULES := true
BOARD_VENDOR_KERNEL_MODULES := $(filter-out \
    $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES) $(BOARD_SYSTEM_KERNEL_MODULES) \
    $(wildcard $(RB3_KERNEL_DIR)/*test*.ko) $(wildcard $(RB3_KERNEL_DIR)/*kunit*.ko) \
    $(wildcard $(RB3_KERNEL_DIR)/ptp_kvm.ko) $(wildcard $(RB3_KERNEL_DIR)/virtio*.ko) \
    $(wildcard $(RB3_KERNEL_DIR)/vmw_vsock_virtio_transport*.ko), \
    $(RB3_KERNEL_MODULES))
# not androidboot.load_modules_parallel: it loaded out of dependency order and hung the boot
