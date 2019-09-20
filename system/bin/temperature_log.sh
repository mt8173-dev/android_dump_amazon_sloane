#!/system/bin/sh

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

BASEPATH=`getprop debug.log.base.path`
TMPSLEEP=`getprop debug.log.temperature.sleep`

[ -z "$TMPSLEEP" ] && TMPSLEEP=30

TEMPERATURE_LOG=$BASEPATH/temperature.$LOGTIMESTAMP.log

PATH_BATTERY=/sys/devices/platform/battery_meter
PATH_THERMAL_TMP103=/sys/devices/platform/tmp103-thermal
PATH_THERMAL_ZONES=/sys/devices/virtual/thermal

# Get the serial number
SERIAL=$(cat /proc/idme/serial)

#echo "#serial[$SERIAL]" >> $TEMPERATURE_LOG
echo "==================================================================\n" >> $TEMPERATURE_LOG

chmod 0600 $TEMPERATURE_LOG
chown system.system $TEMPERATURE_LOG

UPTIME=`cat /proc/uptime`
THERMAL_ZONES_NAME=""
for i in 1 2 3 4 5 6 0; do name=$(cat $PATH_THERMAL_ZONES/thermal_zone${i}/type); THERMAL_ZONES_NAME+="${name},"; done

echo "time,\ttpcb0,\ttpcb1,\ttpcb2,\tbvol,\tbcap,\tbcur,\tblim,\tcpu0freq,\tcpu1freq,\tcpu2freq,\tcpu3freq,\tgpfreq,\tboot_up_time,\tbugd,\t$THERMAL_ZONES_NAME"  >> $TEMPERATURE_LOG

while true; do
	NOW=$(date)
	PCB0_TEMP=`cat /sys/bus/i2c/devices/2-0070/temp1_input`
        PCB1_TEMP=`cat /sys/bus/i2c/devices/2-0071/temp1_input`
        PCB2_TEMP=`cat /sys/bus/i2c/devices/2-0072/temp1_input`

	THERMAL_ZONES=""
	for i in 1 2 3 4 5 6 0; do temp=$(cat $PATH_THERMAL_ZONES/thermal_zone${i}/temp); THERMAL_ZONES+="${temp},"; done

	CPU0_FREQ=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`
	CPU1_FREQ="offline"
	if [ -e /sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq ]; then
	    CPU1_FREQ=`cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq`
	fi
	CPU2_FREQ="offline"
	if [ -e /sys/devices/system/cpu/cpu2/cpufreq/scaling_cur_freq ]; then
	    CPU2_FREQ=`cat /sys/devices/system/cpu/cpu2/cpufreq/scaling_cur_freq`
	fi
	CPU3_FREQ="offline"
	if [ -e /sys/devices/system/cpu/cpu3/cpufreq/scaling_cur_freq ]; then
	    CPU3_FREQ=`cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_cur_freq`
	fi
	GPU_FREQ=`cat /proc/gpufreq/gpufreq`

	BATTERY_VOLTAGE=$(cat $PATH_BATTERY/FG_g_fg_dbg_bat_volt)
	BATTERY_CURRENT=$(cat $PATH_BATTERY/FG_g_fg_dbg_bat_current)
        BATTERY_LIMIT=$(cat $PATH_BATTERY/charging_current_limit)
	BATTERY_CAPACITY=$(cat $PATH_BATTERY/FG_g_fg_dbg_percentage)
	BUDGET=`cat /proc/thermal/thermal_budget`

	UPTIME=`cat /proc/uptime`

	DATA0="$NOW,\t$PCB0_TEMP,\t$PCB1_TEMP,\t$PCB2_TEMP,\t$BATTERY_VOLTAGE,\t$BATTERY_CAPACITY,\t$BATTERY_CURRENT,\t$BATTERY_LIMIT,"
	DATA1="\t$CPU0_FREQ,\t$CPU1_FREQ,\t$CPU2_FREQ,\t$CPU3_FREQ,\t$GPU_FREQ,\t$UPTIME,\t$BUDGET,\t$THERMAL_ZONES"

	echo "$DATA0 $DATA1" >> $TEMPERATURE_LOG

	sleep $TMPSLEEP
done
