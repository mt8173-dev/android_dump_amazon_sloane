#!/system/bin/sh 

DEV_FLAGS_USB_MODE_PERIPHERAL=0x1
FILE2CHECK="/data/hwval/adb_check.bin"
MD5CHECK="27ec1016c3db85fa8bb547ada6d3321e"
NONUSER_BUILD="test-keys"
devflagsfile="/proc/idme/dev_flags"
is_production=`getprop ro.boot.prod`
build_tags=`getprop ro.build.tags`

if [ -e ${FILE2CHECK} ]; then
	CHECKSUM=$(md5 ${FILE2CHECK})
	CHECKSUM=${CHECKSUM%% *}
	if [ "${CHECKSUM}" == "${MD5CHECK}" ]; then
                echo "Enabling adb and usb debugging for first boot" > /dev/kmsg
		setprop sys.usb.debugging y
		setprop sys.usb.config adb
		if [ $NONUSER_BUILD == $build_tags ]; then
		        echo "Device is userdevsigned or userdebug" > /dev/kmsg
			setprop persist.sys.usb.debugging y
			setprop persist.sys.usb.config mtp,adb
		fi
	fi
        rm -rf ${FILE2CHECK}
fi


