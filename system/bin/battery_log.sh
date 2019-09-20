#!/system/bin/sh

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

BASEPATH=`getprop debug.log.base.path`
BATSLEEP=`getprop debug.log.battery.sleep`
BATTERY_LOG=$BASEPATH/battery.$LOGTIMESTAMP.log
BATSLEEP=10

# Get the serial number
SERIAL=`cat /proc/idme/serial`

echo "#serial[$SERIAL]" > $BATTERY_LOG
echo '#time, FG_Aging_Factor, FG_Battery_Cycle, FG_g_fg_dbg_bat_temp, FG_Max_Battery_Temperature, FG_Min_Battery_Temperature, FG_g_fg_dbg_bat_volt, FG_Max_Battery_Voltage, FG_Min_Battery_Voltage, FG_Current, FG_g_fg_dbg_bat_current, FG_Max_Battery_Current, FG_Min_Battery_Current, FG_R_Offset, FG_g_fg_dbg_bat_car, FG_g_fg_dbg_bat_qmax, FG_g_fg_dbg_bat_r, FG_g_fg_dbg_bat_zcv, FG_g_fg_dbg_d0, FG_g_fg_dbg_d1, FG_g_fg_dbg_percentage, FG_g_fg_dbg_percentage_fg, FG_g_fg_dbg_percentage_voltmode' >> $BATTERY_LOG

chmod 0600 $BATTERY_LOG
chown system.system $BATTERY_LOG

while true; do
    NOW=$(date +%s)

	BATTERY_AGING_FACTOR=$(cat /sys/devices/platform/battery_meter/FG_Aging_Factor)
	BATTERY_CYCLE_COUNT=$(cat /sys/devices/platform/battery_meter/FG_Battery_Cycle)
	BATTERY_TEMP=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_temp)
        BATTERY_MAX_TEMPERATURE=$(cat /sys/devices/platform/battery_meter/FG_Max_Battery_Temperature)
	BATTERY_MIN_TEMPERATURE=$(cat /sys/devices/platform/battery_meter/FG_Min_Battery_Temperature)
	BATTERY_VOLTAGE=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_volt)
        BATTERY_MAX_VOLTAGE=$(cat /sys/devices/platform/battery_meter/FG_Max_Battery_Voltage)
	BATTERY_MIN_VOLTAGE=$(cat /sys/devices/platform/battery_meter/FG_Min_Battery_Voltage)
	BATTERY_CURRENT_NOW=$(cat /sys/devices/platform/battery_meter/FG_Current)
	BATTERY_CURRENT=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_current)
        BATTERY_MAX_CURRENT=$(cat /sys/devices/platform/battery_meter/FG_Max_Battery_Current)
	BATTERY_MIN_CURRENT=$(cat /sys/devices/platform/battery_meter/FG_Min_Battery_Current)
	BATTERY_R_OFFSET=$(cat /sys/devices/platform/battery_meter/FG_R_Offset)
	BATTERY_BAT_CAR=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_car)
	BATTERY_CAPACITY_mAH=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_qmax)
	BATTERY_BAT_R=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_r)
	BATTERY_BAT_ZCV=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_bat_zcv)
	BATTERY_BAT_d0=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_d0)
	BATTERY_BAT_d1=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_d1)
	BATTERY_CAPACITY_PER=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage)
	BATTERY_CAPACITY_PER_FG=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage_fg)
	BATTERY_CAPACITY_PER_VOLT=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage_voltmode)

	echo "$NOW, $BATTERY_AGING_FACTOR, $BATTERY_CYCLE_COUNT, $BATTERY_TEMP, $BATTERY_MAX_TEMPERATURE, $BATTERY_MIN_TEMPERATURE, $BATTERY_VOLTAGE, $BATTERY_MAX_VOLTAGE, $BATTERY_MIN_VOLTAGE, $BATTERY_CURRENT_NOW, $BATTERY_CURRENT, $BATTERY_MAX_CURRENT, $BATTERY_MIN_CURRENT, $BATTERY_R_OFFSET, $BATTERY_BAT_CAR, $BATTERY_CAPACITY_mAH, $BATTERY_BAT_R, $BATTERY_BAT_ZCV, $BATTERY_BAT_d0, $BATTERY_BAT_d1, $BATTERY_CAPACITY_PER, $BATTERY_CAPACITY_PER_FG, $BATTERY_CAPACITY_PER_VOLT" >> $BATTERY_LOG
        sleep $BATSLEEP
done
