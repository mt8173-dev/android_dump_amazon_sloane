#!/system/bin/sh


sleep 300  #When the system reboots, wait 5 minutes to start the test

	##############################
	### Initializing variables

if [ -s /data/configs/test.conf ]; then

  testtime=$(busybox head -n1 /data/configs/test.conf)  # read 1st line of test.conf to specify time of test
  cooldowntime=$(busybox head -n2 /data/configs/test.conf | busybox tail -1) # read 2nd line of test.conf to specify cooldown period after test

  testnumber=$(busybox head -n3 /data/configs/test.conf | busybox tail -1) # read 3rd line of test.conf to specify how many tests to run
  i=$(busybox head -n4 /data/configs/test.conf | busybox tail -1) # read 4th line of test.conf to specify how many tests to run
	###
	##############################

  if [ $i -le $testnumber ]; then


	### Main loop
	# Go through each run twice. Once charging, and once discharging
	# Discharge first, so that you can start the test with a fully-charged unit

    for j in 1 2
    do

	##############################
	### Block to specify charge or discharge run

	if [ $j -eq 1 ]; then
	    charging=0
	    echo Charging Enabled before echo 0: $(cat /sys/devices/platform/battery/Charging_Enable) >> /data/TBADebug.log
	    echo 0 > /sys/devices/platform/battery/Charging_Enable
	    str=D
	else
	    charging=1
	    echo Charging Enabled before echo 1: $(cat /sys/devices/platform/battery/Charging_Enable) >> /data/TBADebug.log
	    echo 1 > /sys/devices/platform/battery/Charging_Enable
	    echo Battery charge before charging run: $(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage) >> /data/TBADebug.log
	    str=C

	fi


	echo charging variable = $charging  Charging_Enabled = $(cat /sys/devices/platform/battery/Charging_Enable) >> /data/TBADebug.log
	echo test: $i  timestamp: `date +%s` >> /data/TBADebug.log

	###
	##############################


	##############################
	### Block to start Workload and logs


	echo Brightness before screen turn on: $(cat /sys/class/leds/lcd-backlight/brightness) >> /data/TBADebug.log

	input keyevent 26  # press power button
	sleep 1
	input keyevent 82  # unlock screen
	sleep 1

	echo Brightness after screen turn on: $(cat /sys/class/leds/lcd-backlight/brightness) >> /data/TBADebug.log

	./data/logTempAriel.sh &
	PIDlog=$!
	logcat -v time >> /data/thermald_log.txt &
	PIDlogcat=$!
	sleep 1
	am start -a android.intent.action.MAIN -n com.guildsoftware.vendettamark/.VODispatcher >> /data/TBADebug.log # Start VendettaMark
	echo logTempAriel.sh ProcessID: $PIDlog >> /data/TBADebug.log
	echo logcat ProcessID: $PIDlogcat >> /data/TBADebug.log
	echo Vendetta Mark Process ID: $(ps | grep com.guildsoftware | busybox cut -c11-16) >> /data/TBADebug.log

	### Block to start Workload and logs
	##############################

	##############################
	### Block to sleep while Workload runs


	echo timestamp before sleep fn: `date +%s` >> /data/TBADebug.log

    if [ charging -eq 0 ]; then
	battmin=30
    else			#Set the minimum battery charge that can be reached during the run
	battmin=15		#+this is necessary so that after a discharge run, very restrictive charger
    fi				#actions don't kill the battery, and the test finishes early (solution out of bounds)

	battSoC=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage)
	echo Battery charge before run: $battSoC >> /data/TBADebug.log
	k=0
	check1=$(busybox tail -1 /data/temp.log | busybox cut -c1-10)	#first check if logTempAriel.sh is still running
	while [ $battSoC -gt $battmin ] && [ $k -le $testtime ]	#run for 3 hours or till the battery goes below 25%
	do
		sleep 10
		check2=$(busybox tail -1 /data/temp.log | busybox cut -c1-10)	#second timestamp check
		battSoC=$(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage)
		echo `date +%s` >> /data/cooler.log
		echo $(cat /sys/devices/platform/tmp103-cooling/cooler) >> /data/cooler.log
		k=$(($k + 1))
		if [ check1 -eq check2 ]; then 		#if both timestamps are the same, restart logTempAriel.sh  
		   ./data/logTempAriel.sh & 
		   PIDlog=$! 
		fi
		check1=$check2
	done 
	echo BattSoC variable after run: $battSoC >> /data/TBADebug.log
	echo Battery charge after run: $(cat /sys/devices/platform/battery_meter/FG_g_fg_dbg_percentage) >> /data/TBADebug.log



	echo timestamp after sleep fn: `date +%s` >> /data/TBADebug.log

	### Block to sleep while Workload runs
	##############################

	input keyevent 4     # Stop the game and get to score screen
	echo timestamp after back button pressed: `date +%s` >> /data/TBADebug.log
	sleep 2
	/system/bin/screencap -p /data/Vendetta/Score$str$i.png # take a screenshot of the score
	echo timestamp after screenshot taken: `date +%s` >> /data/TBADebug.log

	##############################
	### Block to Move logs to an appropriate folder

	cp /data/temp.log /data/Vendetta/temp$str$i.log
	cp /data/thermald_log.txt /data/Vendetta/thermald_log$str$i.txt
	cp /data/cooler.log /data/Vendetta/cooler$str$i.log
	#cp /sdcard/Android/data/com. /data/Vendetta/ #change this to get a more usable form of the VM data
	kill -9 $PIDlog     # kill the log and logcat processes
	kill -9 $PIDlogcat
	echo timestamp after logs moved and PSIDs killed: `date +%s` >> /data/TBADebug.log
	sleep 1
	rm /data/thermald_log.txt 
	rm /data/temp.log
	rm /data/cooler.log

	###
	##############################

	input keyevent 66 # Press enter to leave the game
	echo timestamp after leaving the game: `date +%s` >> /data/TBADebug.log

	PIDVM=$(ps | grep com.guildsoftware | busybox cut -c11-16)
	if [ $PIDVM -gt 0 ]; then kill -9 $PIDVM; fi # Kill the Vendetta process in case leaving the game didn't work

	##############################
	### Cooldown Block
	
	echo Brightness before screen turn off: $(cat /sys/class/leds/lcd-backlight/brightness). Timestamp: `date +%s`  >> /data/TBADebug.log
	input keyevent 26  # press power button to turn off screen
	sleep 2
	echo Brightness after screen turn off: $(cat /sys/class/leds/lcd-backlight/brightness). Timestamp: `date +%s` >> /data/TBADebug.log

	echo Cooldown time: $cooldowntime >> /data/TBADebug.log
	echo timestamp before cooldown: `date +%s` >> /data/TBADebug.log
	sleep $cooldowntime # Wait for unit to cool down before starting next test
	echo timestamp after cooldown: `date +%s` >> /data/TBADebug.log

	### 
	##############################
  
	echo end of test $str$i >> /data/TBADebug.log
	echo   >> /data/TBADebug.log

    done

  i=$(($i + 1)) # add 1 to the counter
  echo $testtime > /data/configs/test.conf	# replace last line of test.conf with number of next test
  echo $cooldowntime >> /data/configs/test.conf
  echo $testnumber >> /data/configs/test.conf
  echo $i >> /data/configs/test.conf

  cp /data/configs/conf$i /data/misc/thermal/tmp103-thermal.conf	# replace thermal manager config files
  cp /data/configs/VSconf$i /data/misc/thermal/thermal-virtual-sensor.conf



    if [ $i -gt $testnumber ]; then
	echo The test is over and $(($i - 1)) cases ran >> /data/TBADebug.log
	echo   >> /data/TBADebug.log
	echo   >> /data/TBADebug.log
    fi

  reboot

  else
    echo The test plan is already complete >> /data/TBADebug.log
    echo   >> /data/TBADebug.log
    echo   >> /data/TBADebug.log
  fi
fi


