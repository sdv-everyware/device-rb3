# sdv_media_db845c

SDV media on the Qualcomm Robotics RB3 Development Kit (a DragonBoard 845c): SDV core, a
harry-based UI on the board's GPU, and no Java framework. Bare metal: one image on the
board, no hypervisor, no second machine.

## What the product is made of

| Piece | From | How |
|---|---|---|
| SDV core: init, apexd, servicemanager, keystore2, vold, the SDV services and agents | `device/google/sdv/sdv_core_base/sdv_core_base.mk` | included |
| The board: kernel 6.12 and modules, firmware, fstab, boot HAL, power and thermal HALs | `device/linaro/dragonboard/db845c/device.mk`, `db845c/BoardConfig.mk` | inherited and included; not `db845c.mk` / `full.mk`, which bring the Java framework |
| Graphics: Mesa freedreno (prebuilt), minigbm | the Linaro vendor package (`mesa_prebuilt`), `device/linaro/dragonboard/shared/graphics` | inherited; the Mesa modules are defined in `mesa/Android.mk`, because the package defines them for Linaro's devices only; no drm_hwcomposer, harry drives KMS itself |
| The display for apps on harry: linear buffers, the display driver in first stage, the vendor libraries mesa needs | this folder | the app itself comes with its APEX; the stock harry of display_safety is not in the image |
| Device identity and service discovery for one device | Google's test DICE files, `vvmconfig.example`, the trust store as files | `BoardConfig.mk`, `ethernet/ethernet_sd_mesh_local.sh` |
| Network: Wi-Fi, DHCP, names | `wpa_supplicant`, AOSP's `dhcpclient`, `vendor/sdv-everyware/dnsproxyd` | `net/net_bringup.sh` |
| Time | `vendor/sdv-everyware/third_party/chrony` | started after the RTC |
| The house's services: weather, news, Wi-Fi, Matter, the dashboard bridge | `vendor/sdv-everyware/everyware/product/everyware.mk` | inherited: one APEX each in `/product`; the domains of the Wi-Fi and Matter bundles in `sepolicy/` |
| The smart home panel | `packages/services/display_safety/utils/smarthome-app` | the vendor APEX `com.everyware.smarthome`, started by its own init script; it runs in HAR's domain (`BoardConfig.mk`) |

The product lives under `device/rb3/` so that no `AndroidProducts.mk` of Google or Linaro
is edited: the build picks up every `device/*/AndroidProducts.mk`.

Root init: the kernel's bootconfig names `/system/etc/init/hw/init.sdv_media.rc` and init
reads that file only. Every rc of the board is imported there by name; an rc that is
installed and not listed is never read.

SELinux is permissive (`androidboot.selinux=permissive`): the product is in bring-up, the
denials are the policy still to write. The device identity uses Google's public test
secrets. Both are for development, not for a product.

## Build

The firmware of the board is not in the tree. Fetch and extract the Linaro vendor package
in the tree's root once (it creates `vendor/linaro/`):

```
device/linaro/dragonboard/fetch-vendor-package.sh
```

Leave the package as it is: `mesa/Android.mk` defines its OpenGL ES and Vulkan driver (Mesa)
for this product. If the package's `mesa_prebuilt/Android.mk` names `sdv_media_db845c`, extract
the package again.

```
source device/rb3/sdv_media_db845c/tools/env.sh
m
```

`tools/env.sh` sets `OUT_DIR=out_rb3` and runs lunch. With `RB3_OUT_DISK=<mount point>` the
out directory is kept on another disk.

## Flash

The board runs Linaro's AOSP bootloader; put it into fastboot mode (`adb reboot bootloader`,
or VOL- held while powering on).

```
device/rb3/sdv_media_db845c/tools/flash.sh images   # boot, vendor_boot, super; data stays
device/rb3/sdv_media_db845c/tools/flash.sh all      # also the bootloader; wipes data
```

There is no fastbootd on this board, so a new image of system, vendor or product is flashed as
the whole `super.img`. Between two flashes a userdebug image takes single files with
`adb root; adb remount` (an overlay on `/data` that stays over a reboot); this is how
`vendor/sdv-everyware/everyware/scripts/deploy-bundle-rb3.sh` puts a rebuilt bundle on the
board. The board boots without AVB. Serial console: `ttyMSM0`, 115200.

## Network

Wi-Fi comes up after boot, with DHCP. There is no framework (no ConnectivityService, no
netd), so the product does it itself:

```
dlkm_loader stopped
  ├─ start rmtfs                 modem file server, needed for Wi-Fi
  └─ start vendor.net_bringup    net/net_bringup.sh
       ├─ modem remoteproc offline? start it
       ├─ wlan0: wait 20 s; with /data/vendor/wifi/wpa_supplicant.conf:
       │    IPv6 on for wlan0 (Matter), update_config=1 in the config (the Wi-Fi bundle
       │    saves the networks it joins), wpa_supplicant with the control socket
       │    @abstract:wpa_everyware for the Wi-Fi bundle, and on every connect
       │    dhcpclient -i wlan0
       └─ wait                   the children live as long as the service
dhcpclient: link up, address, default route, MTU;
            gateway and DNS servers as vendor.net.wlan0.gw, vendor.net.wlan0.dns1..4
```

The properties are the contract with the rest of the system: dnsproxyd resolves names with
the servers in `vendor.net.wlan0.dns1..4`, and `init.sdv_db845c.rc` tells chronyd to look
its time servers up again when `dns1` is set. Only wlan0 is brought up.

The Wi-Fi configuration is created on the device and is never part of the image:

```
adb shell 'cat > /data/vendor/wifi/wpa_supplicant.conf' <<'CONF'
ctrl_interface=/data/vendor/wifi/wpa/sockets
network={
    ssid="<name>"
    psk="<passphrase>"
}
CONF
```

Check: `adb logcat -s net_bringup dhcpclient`, `adb shell 'ifconfig wlan0; ip route; getprop | grep vendor.net'`.

What the bring-up works around:

| Trap | Effect | What the product does |
|---|---|---|
| Linaro's `init.utils.rc` starts `rmtfs` before `dlkm_loader` has loaded its modules | rmtfs exits, the modem DSP does not boot, no `wlan0` | starts `rmtfs` again after `dlkm_loader` |
| an interface is brought up right when `dlkm_loader` stops | it registers milliseconds later, the command misses it | the script waits for `/sys/class/net/<if>` |
| init kills a oneshot service's process group when the script exits | dhcpclient and wpa_supplicant die with it | the script ends with `wait` |
| wpa_supplicant drops root before it reads the config | a config made as root (0600) cannot be read | the script sets `wifi:wifi 0660` |
| this wpa_supplicant does not scan by itself | the state stays DISCONNECTED | a watchdog in the script asks for a scan while wlan0 is not connected |

## After the first boot

```
adb shell getprop ro.sdv.profile        # media
adb shell ls -l /dev/dri                # card0: the msm display controller
```

## Not in this product

- The Java framework: zygote, system_server, SurfaceFlinger, wificond, the Android Bluetooth
  stack.
- A second machine or any transport between machines: SDV RPC and service discovery stay on
  the board.
- Sensors: the RB3's sensors sit behind Qualcomm's sensor core, for which AOSP has no HAL.
