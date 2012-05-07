#!/bin/sh

# Very simple test for Raspberry Pi
#  - check there is a (USB) mouse
#  - check there is a (USB) keyboard
#  - check the ethernet exists

cmd_name=rpttestmode

sys_keybd=/sys/class/input/input0
sys_mouse=/sys/class/input/input1
sys_realmouse=/sys/class/input/mouse0/device
sys_vchiq=/sys/class/vchiq/vchiq
sys_led=/sys/class/leds/led0

rc=0

err() { echo "$cmd_name: ***** $*">&2; }
log() { echo "$cmd_name: $*"; }

usb_input_name()
{   local thing="$1"; shift
    local dev="$1"; shift
    local bus
    local name
    local rc

    if [ ! -d $dev ]; then
        err "No $thing device found"
        rc=2
    elif ! name=`cat $dev/name`; then
        err "$thing device has no name - unexpected"
        rc=3
    else
        if ! bus=`cat $dev/id/bustype`; then
            err "$thing device has no bus type - unexpected"
            rc=4
        elif [ "$bus" != "0003" ]; then
            err "$thing bus type is '$bus' - expected 0003"
            rc=5
        fi
        echo "$name"
    fi

    return $rc
}

getmac()
{   local eth="$1"; shift
    local ifc_line
    local rc

    ifc_line=`ifconfig $eth | grep $eth`
    rc=$?
    if [ $rc -eq 0 ]; then
        set -- $ifc_line
        echo $5
    fi

    return $rc
}
        
led()
{   local dev="$1"; shift
    local bright="$1"; shift
    [ "$bright" = "on" ] && bright=255
    [ "$bright" = "off" ] && bright=0
    echo $bright > $dev/brightness
    return $?
}

if [ ! -d /sys ]; then
    err "/sys missing - no sysfs mounted?"
    rc=1
else
    keybd_name=`usb_input_name Keyboard $sys_keybd` || rc=$?
    [ -z "$keybd_name" ] || log "keyboard: $keybd_name"
    mouse_name=`usb_input_name Mouse $sys_mouse` || rc=$?
    [ -z "$mouse_name" ] || log "mouse: $mouse_name"
    realmouse_name=`usb_input_name Mouse $sys_realmouse` || rc=$?
    if [ $rc -eq 0 ]; then
        if [ "$mouse_name" != "$realmouse_name" ]; then
            err "first mouse is not assumed mouse device"
            rc=6
        fi
    fi
    eth0_mac=`getmac eth0` || rc=$?
    if [ -z "$eth0_mac" ]; then
        err "no MAC address found for eth0"
        rc=7
    else
        log "eth0 is present with MAC address $eth0_mac"
    fi
    if [ ! -d $sys_led ]; then
        err "No LED device found"
        rc=8
    else
        if ! led $sys_led off; then
            err "Can't control LED brightness"
            rc=9
        elif [ $rc -eq 0 ]; then
            ledon=false
            log "flashing LED forever"
            # flash LED forever
            while sleep 1; do
                if $ledon; then
                    led $sys_led off
                    ledon=false
                else
                    led $sys_led on
                    ledon=true
                fi
            done
        fi
    fi
fi


exit $rc
