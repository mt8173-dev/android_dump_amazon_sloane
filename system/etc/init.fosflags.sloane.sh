#!/system/bin/sh

export FOS_FLAGS_ADB_ON=0x1
DEV_FLAGS_USB_MODE_PERIPHERAL=0x1
FILE2CHECK="/data/hwval/adb_check.bin"

# General FOS flags, shared across devices
fosflagsfile="/proc/idme/fos_flags"
# Optional device specific flags
devflagsfile="/proc/idme/dev_flags"


if [ -e ${FILE2CHECK} ]; then
	echo "First boot adb will be enable at bootcomplete" > /dev/kmsg
else
	if [ -f $fosflagsfile ] ; then
		export FOSFLAGS=`cat $fosflagsfile`
		log -t FOSFLAGS Read FOS flags:$FOSFLAGS
		echo "Read fos_flag:$FOSFLAGS " > /dev/kmsg
		if [ $(( $FOS_FLAGS_ADB_ON & 0x$FOSFLAGS )) != 0 ]; then
			log -t FOSFLAGS "Enabling adb USB debugging from FOS flags"
			echo "setting usb to device mode on fos_flag" > /dev/kmsg
			setprop persist.sys.usb.debugging y
			setprop sys.usb.config mtp,adb
		fi
	fi
fi


