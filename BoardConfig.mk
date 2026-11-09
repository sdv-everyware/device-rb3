# Linaro's board config first (it sets TARGET_BOARD_PLATFORM, which keys kernel, dtb, fstab and
# sepolicy of the board), then the SDV pieces.

include device/linaro/dragonboard/db845c/BoardConfig.mk

# only errors on the 115200 baud serial console: every printed line costs 7 ms of boot
BOARD_KERNEL_CMDLINE += loglevel=4

BOARD_SEPOLICY_DIRS += device/google/sdv/sdv_core_base/sepolicy/vendor/

include device/google/sdv/sdv_core_base/sepolicy/samples/board_sepolicy.mk

BOARD_VENDOR_SEPOLICY_DIRS += device/rb3/sdv_media_db845c/sepolicy/vendor

# the root init: init reads this file and its imports only. Every bootconfig key once across
# this file and vendor_boot, or the kernel drops the whole bootconfig. Permissive while the
# denials of the board are collected.
BOARD_BOOTCONFIG += \
    androidboot.init_rc=/system/etc/init/hw/init.sdv_media.rc \
    androidboot.adb.enabled=1 \
    androidboot.selinux=permissive

# identity: instance1 of Google's example mesh (sdv_core_cf/config/config_sdv_dev_mesh_instance1.json)
BOARD_BOOTCONFIG += \
    androidboot.sdv.instance_name=instance1 \
    androidboot.sdv.init_open_dice.sample_file=dice_handover_instance1 \
    androidboot.sdv.boot_mode=locked \
    androidboot.sdv.ignore_avb_state=true \
    androidboot.sdv.preprovisioned_vvmtruststore=etc \
    androidboot.sdv.vvmfactorytrust=c779a73d0595a6814ba0414a419e99ad4026ad0feb603f2ad80ee6a9e4d1adb7 \
    androidboot.sdv.keymint.rpc.hbk=799da7577efd41d5b27810c5952fcec0291cbcfd687e77ac9a6cec8370651b1d \
    androidboot.vbmeta.digest=a0c829a2b0bc8be1114201dcbea3e435edddd9cc50cb65d2cb9aae92e2406f05 \
    androidboot.sdv.rpc.interface=lo

# vbmeta.digest is a placeholder: the bootloader boots without AVB and passes none, and
# sdv_sd_agent rejects all zeros. Development only. sdv.rpc.interface: the SDV RPC servers
# bind to this interface's address; loopback keeps them on the device.

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
