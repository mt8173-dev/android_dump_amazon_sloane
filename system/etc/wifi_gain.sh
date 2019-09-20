#!/system/bin/sh

LOGNAME="wifi_gain"
IWPRIV=/system/xbin/iwpriv

function set_gain_value ()
{
    antenna_one_gain_value=`getprop debug.wifi.gain.modify.antenna1`
    antenna_two_gain_value=`getprop debug.wifi.gain.modify.antenna2`
    $IWPRIV wlan0 set enable_dynamic_vga=0
    log "main.$LOGNAME" "Setting antenna1 gain to $antenna_one_gain_value"
    $IWPRIV wlan0 mac 2320=$antenna_one_gain_value
    log "main.$LOGNAME" "Setting antenna2 gain to $antenna_two_gain_value"
    $IWPRIV wlan0 mac 2324=$antenna_two_gain_value
}

antenna_modify_gain_value=`getprop debug.wifi.gain.modify.antenna`

if [[ $antenna_modify_gain_value = "reset" ]];then
    set_gain_value
elif [[ $antenna_modify_gain_value = "set" ]];then
    p2p_frequency_str=`getprop persist.sys.p2p.go.chnl`
    typeset -i p2p_freq=$p2p_frequency_str
    log "main.$LOGNAME" "p2p_freq = $p2p_freq"
    if [[ $p2p_freq -lt 5000 && $p2p_freq -gt 0 ]];then
        set_gain_value
    fi
elif [[ $antenna_modify_gain_value = "initialize" ]];then
    antenna_one_gain_value_line=`$IWPRIV wlan0 mac 2320 | grep 2320`
    antenna_two_gain_value_line=`$IWPRIV wlan0 mac 2324 | grep 2324`
    antenna_one_gain_value=${antenna_one_gain_value_line:9:8}
    antenna_two_gain_value=${antenna_one_gain_value_line:9:8}
    setprop debug.wifi.gain.modify.antenna1 $antenna_one_gain_value
    setprop debug.wifi.gain.modify.antenna2 $antenna_two_gain_value    
fi
