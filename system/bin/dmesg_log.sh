#!/system/bin/sh

# collect dmesg logs for boot.
sleep 30

ENABLED=`getprop debug.log.dmesg.enable`
if [ "$ENABLED" != "y" ]; then
    exit;
fi;

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

export BASEPATH=`getprop debug.log.base.path`

data_is_blk=$(mount | grep /data | grep block)
if [ "x$data_is_blk" == "x" ]; then
    BASEPATH="/cache/crypt/$BASEPATH"
fi

LOGNAME=$BASEPATH/dmesg.boot.$LOGTIMESTAMP.log
LASTKMSG=$BASEPATH/last_kmsg.$LOGTIMESTAMP.log

mkdir -p $BASEPATH/archive
mv $BASEPATH/*.log $BASEPATH/archive

#To avoid duplicate logs when restarting the script
#Delete old log file if exist
if [ -e $LOGNAME ]; then
	rm $LOGNAME
fi;

if [ -e $LASTKMSG ]; then
	rm $LOGNAME
fi;

echo "********************* START *********************" > $LOGNAME
chmod 0600 $LOGNAME
chmod 0600 $LASTKMSG
chown system.system $LOGNAME
chown system.system $LASTKMSG

#Notify user if /proc/last_kmsg does not exist
if [ -e /proc/last_kmsg ]; then
	cat /proc/last_kmsg >> $LASTKMSG
else
	echo "/proc/last_kmsg does not exist!" >> $LASTKMSG
fi

/system/bin/dmesg >> $LOGNAME

# Detection for RO remount of /userdata
if [ $? -ne 0 ]; then
    BASEPATH=/cache/$BASEPATH
    LOGNAME=$BASEPATH/dmesg.boot.$LOGTIMESTAMP.log

    mkdir -p $BASEPATH
    /system/bin/dmesg >> $LOGNAME
fi;
