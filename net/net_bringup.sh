#!/vendor/bin/sh
# Wi-Fi with DHCP without the framework, started by init.sdv_db845c.rc. wpa_supplicant and
# dhcpclient run as children of this script (init kills the process group when the main
# process exits); dhcpclient sets address, route and MTU and publishes the gateway and the
# DNS servers as vendor.net.wlan0.*.

log() { /vendor/bin/log -t net_bringup "$*"; }

sockets=/data/vendor/wifi/wpa/sockets

wait_iface() {
    i=0
    while [ ! -e /sys/class/net/$1 ]; do
        [ $i -ge $2 ] && return 1
        sleep 1
        i=$((i + 1))
    done
}

# The supplicant (built for the framework) scans only on command: a scan every 5 s while not
# connected. dhcpclient on every connect, not before: started early its DISCOVERs go nowhere
# and it backs off for seconds. From here as root: wpa_cli's action script would run as wifi.
wifi_watchdog() {
    wpa="/vendor/bin/wpa_cli -p $sockets -i wlan0"
    dhcp=
    connected=no
    tick=25
    while true; do
        # a plain STATUS would re-send the connected events to every monitor
        case "$($wpa raw STATUS-NO_EVENTS 2>/dev/null)" in
            *wpa_state=COMPLETED*)
                if [ $connected = no ]; then
                    connected=yes
                    [ -n "$dhcp" ] && kill $dhcp 2>/dev/null
                    /vendor/bin/dhcpclient -i wlan0 &
                    dhcp=$!
                    log "wlan0 connected, dhcpclient started"
                fi
                sleep 1 ;;
            *wpa_state=SCANNING*|*wpa_state=*ASSOCIATING*|*wpa_state=AUTHENTICATING*|*HANDSHAKE*)
                connected=no
                sleep 0.2 ;;
            *)
                connected=no
                if [ $tick -ge 25 ]; then
                    $wpa scan > /dev/null && log "wlan0 not connected, scan"
                    tick=0
                fi
                tick=$((tick + 1))
                sleep 0.2 ;;
        esac
    done
}

for rp in /sys/class/remoteproc/remoteproc*; do
    if [ "$(cat $rp/name)" = 4080000.remoteproc ] && [ "$(cat $rp/state)" = offline ]; then
        echo start > $rp/state
        log "modem started"
    fi
done

# the config (SSID, passphrase) is created on the device, never in the image
conf=/data/vendor/wifi/wpa_supplicant.conf
if ! wait_iface wlan0 20; then
    log "no wlan0"
elif [ ! -f $conf ]; then
    log "no $conf, Wi-Fi stays off"
else
    # the supplicant reads the config as wifi
    chown wifi:wifi $conf
    chmod 0660 $conf
    /vendor/bin/hw/wpa_supplicant -Dnl80211 -iwlan0 -c$conf -O$sockets &
    log "wpa_supplicant started"
    wifi_watchdog &
fi

wait
