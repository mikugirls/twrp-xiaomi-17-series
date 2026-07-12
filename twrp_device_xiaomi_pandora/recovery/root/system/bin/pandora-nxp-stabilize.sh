#!/system/bin/sh
# combined_v26 pandora-only NXP stabilization gate.
# Keep the v20 topology intact while recovering from the early restart storm
# seen on bad pandora boots.

LOG=/tmp/recovery.log
PREFIX="twrp.pandora.combined_v26"

log_msg() {
    echo "combined_v26 pandora-nxp-stabilize: $1" >> "$LOG"
    log -t combined_v26_pandora_nxp "$1" 2>/dev/null || true
}

wait_prop_running() {
    name="$1"
    limit="$2"
    i=0
    while [ "$i" -lt "$limit" ]; do
        [ "$(getprop "init.svc.$name")" = "running" ] && return 0
        sleep 1
        i=$((i + 1))
    done
    return 1
}

wait_stable_running() {
    name="$1"
    stable_needed="$2"
    limit="$3"
    stable=0
    i=0
    while [ "$i" -lt "$limit" ]; do
        if [ "$(getprop "init.svc.$name")" = "running" ]; then
            stable=$((stable + 1))
            [ "$stable" -ge "$stable_needed" ] && return 0
        else
            stable=0
        fi
        sleep 1
        i=$((i + 1))
    done
    return 1
}

ensure_stable_running() {
    name="$1"
    stable_needed="$2"
    limit="$3"

    if wait_stable_running "$name" "$stable_needed" "$limit"; then
        return 0
    fi

    log_msg "$name unstable; restarting once"
    stop "$name"
    sleep 1
    start "$name"
    wait_stable_running "$name" "$stable_needed" "$limit"
}

variant="$(getprop twrp.variant.detected)"
keymint="$(getprop ro.keymint)"
if [ "$variant" != "pandora" ] || [ "$keymint" != "nxp" ]; then
    log_msg "skip variant=$variant keymint=$keymint"
    exit 0
fi

setprop "$PREFIX.nxp_gate_started" 1
setprop "$PREFIX.nxp_gate_error" ""
setprop "$PREFIX.strongbox_ready" 0
setprop "$PREFIX.weaver_ready" 0

start vendor.secure_element
if ! wait_prop_running vendor.secure_element 20; then
    setprop "$PREFIX.nxp_gate_error" "vendor_secure_element_not_running"
    log_msg "vendor.secure_element not running"
    exit 0
fi

start se_omapi
if ! wait_prop_running se_omapi 20; then
    setprop "$PREFIX.nxp_gate_error" "se_omapi_not_running"
    log_msg "se_omapi not running"
    exit 0
fi

sleep 3

if ! ensure_stable_running odm.keymint-strongbox-nxp 3 12; then
    setprop "$PREFIX.nxp_gate_error" "strongbox_nxp_not_stable"
    log_msg "odm.keymint-strongbox-nxp not stable"
    exit 0
fi
setprop "$PREFIX.strongbox_ready" 1
log_msg "strongbox_nxp stable"

sleep 2

if ! ensure_stable_running odm.weaver_nxp 3 12; then
    setprop "$PREFIX.nxp_gate_error" "weaver_nxp_not_stable"
    log_msg "odm.weaver_nxp not stable"
    exit 0
fi
setprop "$PREFIX.weaver_ready" 1
log_msg "weaver_nxp stable"
exit 0
