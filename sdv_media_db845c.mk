# sdv_media_db845c: SDV Media (SDV core, apps on harry, no Java framework) on the Qualcomm
# RB3 (DragonBoard 845c). SDV core base with its own root init (BoardConfig.mk) plus Linaro's
# board files, but not db845c.mk / full.mk, which bring the whole framework.

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# as sdv_core_arm64.mk; the core base errors without them
SDV_VM_LEVEL_PERMISSIONS_MODULE := com.oem.sdv.authz.allow_all.core
SDV_SOMEIP_BROKER_CONFIG := broker_config.json
PRODUCT_SYSTEM_PROPERTIES += ro.sdv.someip.broker_config=/system/etc/someip/broker_config.json
# keystore2 needs a KeyMint; no TEE in AOSP for this board, so SDV's nonsecure one
PRODUCT_PACKAGES += android.sdv.hardware.security.keymint-service.nonsecure
SDV_VEHICLE_POWER_STATE_MANAGER_MODULE := vepsm
SDV_DIAGNOSTICS_AGENT_MODULE := sdv_diagnostics_agent

include device/google/sdv/sdv_core_base/sdv_core_base.mk

# The house link between the panel (vendor) and the dashboard bundle (product): VINTF checks a
# vendor HAL against a framework matrix, and its client lives on /product.
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += device/rb3/sdv_media_db845c/vintf/product_compatibility_matrix.xml

# the core base sets ro.soc.* for a VM, db845c/device.mk sets the real chip: a property once only
PRODUCT_VENDOR_PROPERTIES := $(filter-out ro.soc.manufacturer=% ro.soc.model=%,$(PRODUCT_VENDOR_PROPERTIES))
# the board's system_dlkm writes its own build.prop; the Soong module doubles the path
PRODUCT_PACKAGES := $(filter-out system_dlkm-build.prop,$(PRODUCT_PACKAGES))

# the core base's ueventd.rc imports /vendor/etc/sdv_core_ueventd/: the board's device nodes go there
PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/ueventd.common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/sdv_core_ueventd/ueventd.db845c.rc

PRODUCT_COPY_FILES += \
    device/google/sdv/sdv_core_arm64/sdv_product_native_services_names:$(TARGET_COPY_OUT_PRODUCT)/etc/sdv_native_services_names

PRODUCT_NAME := sdv_media_db845c
PRODUCT_DEVICE := sdv_media_db845c
PRODUCT_BRAND := Android
PRODUCT_MODEL := SDV media on DragonBoard 845c
PRODUCT_MANUFACTURER := Google

# the board: Linaro's device.mk (kernel 6.12, dlkm_loader, fstab, firmware, HALs) and the GPU
# stack; no drm_hwcomposer, harry drives KMS itself
$(call inherit-product, device/linaro/dragonboard/shared/graphics/mesa/device.mk)
$(call inherit-product, device/linaro/dragonboard/shared/graphics/minigbm_msm/device.mk)
$(call inherit-product, device/linaro/dragonboard/db845c/device.mk)

# minigbm would allocate UBWC buffers, which harry's scanout shows as noise
PRODUCT_VENDOR_PROPERTIES += vendor.minigbm.debug=nocompression

# Linaro's prebuilt mesa needs these in the vendor namespace; nothing else here pulls them in
PRODUCT_PACKAGES += \
    libui.vendor \
    libhardware.vendor

# harry's renderer, for an app run from /data/local/tmp during development
PRODUCT_PACKAGES += libimpeller

# Linaro's vendor scripts (set_udc.sh: adb over USB) need a vendor shell and toybox
PRODUCT_PACKAGES += \
    sh_vendor \
    toybox_vendor \
    awk_vendor

# userdata is f2fs with metadata encryption; the core base brings the ext4 tools only
PRODUCT_PACKAGES += \
    fsck.f2fs \
    secdiscard

# Qualcomm remote processors (modem with the Wi-Fi firmware, ADSP), from full.mk
PRODUCT_PACKAGES += \
    pd-mapper \
    qrtr-ns \
    qrtr-cfg \
    qrtr-lookup \
    rmtfs \
    tqftpserv
PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/shared/utils/init.utils.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.utils.rc

# audio: the AIDL HAL apex and its policy files (full.mk); harry plays through tinyalsa
PRODUCT_PACKAGES += \
    com.android.hardware.audio \
    libtinyalsav2 \
    tinyplay \
    tinycap \
    tinymix \
    tinypcminfo
PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    hardware/interfaces/audio/aidl/default/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml

# Bluetooth: the HAL only; the Android stack is Java
PRODUCT_PACKAGES += android.hardware.bluetooth-service.default

# Wi-Fi: wpa_supplicant only (wificond is framework), started by net/net_bringup.sh
FORCE_USE_ANDROIDMK_FOR_WPA_CONF := true
PRODUCT_PACKAGES += \
    wpa_supplicant \
    wpa_supplicant.conf \
    wpa_cli
PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

# the board's init without the framework (in place of Linaro's init.db845c.rc)
PRODUCT_COPY_FILES += \
    device/rb3/sdv_media_db845c/init.sdv_db845c.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.sdv_db845c.rc

# network without the framework: AOSP's dhcpclient (Trusty's, in a Soong namespace) and the script
PRODUCT_SOONG_NAMESPACES += device/generic/trusty
PRODUCT_PACKAGES += dhcpclient
PRODUCT_COPY_FILES += \
    device/rb3/sdv_media_db845c/net/net_bringup.sh:$(TARGET_COPY_OUT_VENDOR)/bin/net_bringup.sh

# the root init (androidboot.init_rc in BoardConfig.mk): init reads this file and its imports only
PRODUCT_COPY_FILES += \
    device/rb3/sdv_media_db845c/init.sdv_media.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/hw/init.sdv_media.rc

# SDV on one device: the sample policies, the test identity, service discovery on loopback
include device/google/sdv/sdv_core_base/sepolicy/samples/device_sepolicy.mk

# identity: instance1 of Google's example mesh, DICE from a test file. Test secrets, development only
include device/google/sdv/sdv_base/init_open_dice/init_open_dice_from_file.mk
PRODUCT_PACKAGES += vvmconfig.example
# sdv_sd_agent panics without an ACL provider
$(call soong_config_set,sdv_authz,acl_provider_type,sdv_acl_provider)
# the trust store of instance1 from /product/etc: the board has no vvmtruststore partition
PRODUCT_PACKAGES += \
    vvmtruststore.preprovisioned.rc \
    vvmtruststore_instance1_etc_uds_certs \
    vvmtruststore_instance1_etc_uds_pubs

# the network namespaces the SDV agents enter, with loopback only: no mesh on one device
PRODUCT_COPY_FILES += \
    device/rb3/sdv_media_db845c/ethernet/ethernet_sd_mesh_local.sh:$(TARGET_COPY_OUT_PRODUCT)/bin/ethernet/ethernet_sd_mesh_local.sh

# the media profile; the app comes with its own APEX. Not the stock harry: its sample config
# names Cuttlefish's displays, and its safety monitor spins without it
PRODUCT_SYSTEM_PROPERTIES += ro.sdv.profile=media

PRODUCT_COPY_FILES += \
    device/rb3/sdv_media_db845c/init.sdv_media_db845c.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.sdv_media_db845c.rc

include device/google/sdv/sdv_media_base/sdv_samples_media.mk

# name resolution without netd
$(call inherit-product, vendor/sdv-everyware/dnsproxyd/dnsproxyd.mk)

# the clock over NTP: no RTC battery, the board boots in 1970 and TLS certificates are "not yet valid"
$(call inherit-product, vendor/sdv-everyware/third_party/chrony/chrony.mk)

# the service bundles of the house (weather, news, Wi-Fi, Matter, the dashboard bridge), one
# APEX each, and the contexts that put them into their SELinux domains
$(call inherit-product, vendor/sdv-everyware/everyware/product/everyware.mk)

# the domains of the two bundles that reach the network themselves (everyware/bundles/wifi and
# /matter): the Wi-Fi bundle talks to the supplicant's control socket, the Matter bundle has
# UDP and multicast; the supplicant's side of the socket is in sepolicy/vendor
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += device/rb3/sdv_media_db845c/sepolicy/system_ext/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/rb3/sdv_media_db845c/sepolicy/system_ext/private

# the panel: a vendor APEX with its harry app, started by its own init script (smarthome-app's
# apex/). The app keeps HAR's domain vendor_harplatform (BoardConfig.mk), and the bundles bind
# TCP sockets (the dashboard's gRPC): HAR's own policy, as harry_apex/product.mk wires it
PRODUCT_PACKAGES += com.everyware.smarthome
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += packages/services/display_safety/service/product/har_sdv_service_bundle_apex/lifecycle/sepolicy/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += packages/services/display_safety/service/product/har_sdv_service_bundle_apex/lifecycle/sepolicy

# adb remount on a userdebug build: the tools of the overlay on /data (android-17.0.0_r1's
# sdv_core_base does not ship them yet). Without them a bundle can only reach the board by
# flashing; with them deploy-bundle-rb3.sh writes /product and /vendor between flashes.
PRODUCT_PACKAGES_DEBUG += \
    remount \
    overlay_remounter \
    gsid
