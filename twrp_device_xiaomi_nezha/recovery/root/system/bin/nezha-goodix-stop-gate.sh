#!/system/bin/sh
# combined_v26 nezha-only post-bootstrap cleanup gate.
# Wait for the correct qti/eSE1 + thales branch, then stop the Goodix eSE2
# sidecar that pollutes the post-PIN decrypt path.

LOG=/tmp/recovery.log
PREFIX="twrp.nezha.combined_v26"

log_msg() {
    echo "combined_v26 nezha-goodix-stop-gate: $1" >> "$LOG"
    log -t combined_v26_nezha_gate "$1" 2>/dev/null || true
}

wait_prop_stable_running() {
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

wait_prop_stopped() {
    name="$1"
    limit="$2"
    i=0
    while [ "$i" -lt "$limit" ]; do
        [ "$(getprop "init.svc.$name")" = "stopped" ] && return 0
        sleep 1
        i=$((i + 1))
    done
    return 1
}

wait_log_pattern() {
    pattern="$1"
    limit="$2"
    i=0
    while [ "$i" -lt "$limit" ]; do
        if logcat -d 2>/dev/null | grep -F "$pattern" >/dev/null 2>&1; then
            return 0
        fi
        if dmesg 2>/dev/null | grep -F "$pattern" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    return 1
}

variant="$(getprop twrp.variant.detected)"
keymint="$(getprop ro.keymint)"
if [ "$variant" != "nezha" ] || [ "$keymint" != "thales" ]; then
    log_msg "skip variant=$variant keymint=$keymint"
    exit 0
fi

setprop "$PREFIX.started" 1
setprop "$PREFIX.error" ""
setprop "$PREFIX.goodix_stopped" 0

if ! wait_prop_stable_running vendor.secure_element 2 20; then
    setprop "$PREFIX.error" "vendor_secure_element_not_stable"
    log_msg "vendor.secure_element not stable"
    exit 0
fi
if ! wait_prop_stable_running se_omapi 2 20; then
    setprop "$PREFIX.error" "se_omapi_not_stable"
    log_msg "se_omapi not stable"
    exit 0
fi
if ! wait_prop_stable_running odm.weaver_hal_service 2 20; then
    setprop "$PREFIX.error" "weaver_hal_not_stable"
    log_msg "odm.weaver_hal_service not stable"
    exit 0
fi
if ! wait_log_pattern "android.hardware.weaver.IWeaver/default" 45; then
    setprop "$PREFIX.error" "weaver_default_not_ready"
    log_msg "IWeaver/default not observed in logs"
    exit 0
fi

stop odm.secure_element_hal_service
if ! wait_prop_stopped odm.secure_element_hal_service 20; then
    setprop "$PREFIX.error" "goodix_secure_element_not_stopped"
    log_msg "odm.secure_element_hal_service did not stop"
    exit 0
fi

setprop "$PREFIX.goodix_stopped" 1
log_msg "goodix secure element stopped after qti/thales branch became ready"
exit 0
