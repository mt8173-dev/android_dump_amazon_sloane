#!/system/bin/sh

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

BASEPATH=`getprop debug.log.base.path`

mkdir -p $BASEPATH
chown system.system $BASEPATH
chmod 0700 $BASEPATH

LOGNAME=$BASEPATH/logcat.$LOGTIMESTAMP.log

echo > $LOGNAME
chmod 0600 $LOGNAME
chown system.system $LOGNAME

opt_trace="-v thread -v time -f $LOGNAME -r256 -n 100 -s *:D"
for buf in `ls /dev/log/`;
do
	if [ "$buf" != "ksystem" ]; then
		opt_bufs+=" -b $buf "
	fi;
done;

logcat $opt_bufs $opt_trace
