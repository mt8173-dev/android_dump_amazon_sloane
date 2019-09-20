#!/system/bin/sh

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

# wait for DropBoxManagerService to add previous log to dropbox
sleep 10

BASEPATH=`getprop debug.log.base.path`
BUILD_TYPE=`getprop ro.build.type`
THERMAL_LOG=$BASEPATH/thermal_log.$LOGTIMESTAMP.log

if [[ -f $BASEPATH/thermal_log_interval ]]; then
    echo "start battery_log."
    INTERVAL=$(cat $BASEPATH/thermal_log_interval)
    echo "interval is $INTERVAL"
    if [[ -z $INTERVAL ]]; then
        INTERVAL=1;
        echo "interval by default is $INTERVAL";
    fi
else
    if [ "$BUILD_TYPE" == "userdebug" ]; then
        INTERVAL=30;
        echo "enable thermal_log for userdebug";
    else
        echo "disable thermal_log."
        exit
    fi
fi

# Get the serial number
SERIAL=`cat /proc/idme/serial`

echo "#serial[$SERIAL]" > $THERMAL_LOG
echo "==================================================================\n" >> $THERMAL_LOG
echo "time,batt_temp,pcb0_temp,pcb1_temp,pcb2_temp,vs_temp,cpu_temp,pmic_temp,cpu_freq,gpu_freq,batt_cap,batt_curr" >> $THERMAL_LOG
chmod 0600 $THERMAL_LOG
chown system.system $THERMAL_LOG

while true; do
	NOW=$(date +%s)
	BATTERY_TEMP=`cat /sys/class/thermal/thermal_zone0/temp`
	PCB0_TEMP=`cat /sys/bus/i2c/devices/2-0070/temp1_input`
	PCB1_TEMP=`cat /sys/bus/i2c/devices/2-0071/temp1_input`
	PCB2_TEMP=`cat /sys/bus/i2c/devices/2-0072/temp1_input`
	VS_TEMP=`cat /sys/class/thermal/thermal_zone6/temp`
	CPU_TEMP=`cat /sys/class/thermal/thermal_zone2/temp`
	PMIC_TEMP=`cat /sys/class/thermal/thermal_zone3/temp`
	CPU_FREQ=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`
	GPU_FREQ=`cat /proc/gpufreq/gpufreq`
	BATTERY_CAPACITY=`cat /sys/class/power_supply/battery/capacity`
	BATTERY_CURRENT=`cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_current`

	echo "$NOW,$BATTERY_TEMP    ,$PCB0_TEMP    ,$PCB1_TEMP    ,$PCB2_TEMP    ,$VS_TEMP  ,$CPU_TEMP   ,$PMIC_TEMP    ,$CPU_FREQ ,$GPU_FREQ  ,$BATTERY_CAPACITY     ,$BATTERY_CURRENT" >> $THERMAL_LOG
	sleep $INTERVAL
done
