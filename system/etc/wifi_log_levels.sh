#!/system/bin/sh

LOGSRC="wifi"
LOGNAME="wifi_log_levels"
METRICSTAG="metrics.$LOGNAME"
LOGCATTAG="main.$LOGNAME"
DELAY=120
LOOPSTILMETRICS=29 # Should send to metrics buffer every hour
currentLoop=0
IWPRIV=/system/xbin/iwpriv

if [ ! -x $IWPRIV ] ; then
	exit
fi

function set_wlan_interface ()
{
	NETCFG=($(netcfg | grep wlan))
	if [[ ${NETCFG[1]} = "UP" ]]; then
		WLAN_INTERFACE=${NETCFG[0]};
	else
		unset $WLAN_INTERFACE
	fi
}

function iwpriv_conn_status ()
{
	IFS='
	'
	CONN_STATUS=($($IWPRIV $WLAN_INTERFACE connStatus))
	CONN_STATUS=${CONN_STATUS#*connStatus:}
	CONN_STATUS=${CONN_STATUS%%\(*}
	unset IFS
}

function iwpriv_stat_tokens ()
{
	IFS='
	'
	STAT=($($IWPRIV $WLAN_INTERFACE stat))

	for line in ${STAT[@]}; do
		case $line in
			"Tx success"*)
				TXFRAMES=${line#*= }
				;;
			"Tx retry count"*)
				TXRETRIES=${line#*= }
				TXRETRIES=${TXRETRIES%,*}
				TXPER=${line#*PER=}
				;;
			"Tx fail to Rcv ACK"*)
				TXRETRYNOACK=${line#*= }
				TXRETRYNOACK=${TXRETRYNOACK%,*}
				TXPLR=${line#*PLR=}
				;;
			"Rx success"*)
				RXFRAMES=${line#*= }
				;;
			"Rx with CRC"*)
				RXCRC=${line#*= }
				RXCRC=${RXCRC%,*}
				RXPER=${line#*PER=}
				;;
			"Rx drop due to out of resource"*)
				RXDROP=${line#*= }
				;;
			"Rx duplicate frame"*)
				RXDUP=${line#*= }
				;;
			"False CCA(total)"*)
				TOTALCCA=${line#*= }
				;;
			"False CCA(one-second)"*)
				ONECCA=${line#*= }
				;;
			"RSSI"*)
				if [ "$HADRSSI" -eq 0 ]; then
					RSSI=${line#*= }
					HADRSSI=1
				fi
				;;
			"P2P GO RSSI"*)
				P2PRSSI=${line#*= }
				;;
			"PhyMode:"*)
				if [[ "$HADPHYRATE" -eq 0  &&
					"$RSSI" != "0 0" ]] ; then
					PHYMODE=${line#*: }
					PHYMODE=${PHYMODE%PhyRate*}
					PHYRATE=${line#*PhyRate:}
				else
					P2PPHYMODE=${line#*: }
					P2PPHYMODE=${PHYMODE%PhyRate*}
					P2PPHYRATE=${line#*PhyRate:}
				fi
				HADPHYRATE=1
				;;
			"Last TX Rate"*)
				if [ "$HADLASTTXRATE" -eq 0 ]; then
					LASTTXRATE=${line#*= }
					HADLASTTXRATE=1
				else
					P2PLASTTXRATE=${line#*= }
				fi
				;;
			"Last RX Rate"*)
				if [ "$HADLASTRXRATE" -eq 0 ]; then
					LASTRXRATE=${line#*= }
					HADLASTRXRATE=1
				else
					P2PLASTRXRATE=${line#*= }
				fi
				;;
			"SNR-A"*)
				SNRA=${line#*= }
				;;
			"SNR-B"*)
				SNRB=${line#*= }
				;;
			"NoiseLevel-A"*)
				NOISEA=${line#*= }
				;;
			"NoiseLevel-B"*)
				NOISEB=${line#*= }
				;;
			"P2P SNR-A"*)
				P2PSNRA=${line#*= }
				;;
			"P2P SNR-B"*)
				P2PSNRB=${line#*= }
				;;
			"P2P NoiseLevel-A"*)
				P2PNOISEA=${line#*= }
				;;
			"P2P NoiseLevel-B"*)
				P2PNOISEB=${line#*= }
				;;
		esac
	done

	unset IFS
}

function get_max_signal_stats
{
	arrRssi=(`echo ${RSSI}`)
	if [ "${arrRssi[0]}" -gt "${arrRssi[1]}" ] ; then
		maxRssi=${arrRssi[0]}
	else
		maxRssi=${arrRssi[1]}
	fi

	# update RSSI property
	setprop 'wifi.ro.wlan0.rssi' $maxRssi

	arrP2pRssi=(`echo ${P2PRSSI}`)
	if [ "${arrP2pRssi[0]}" -gt "${arrP2pRssi[1]}" ] ; then
		maxP2pRssi=${arrP2pRssi[0]}
	else
		maxP2pRssi=${arrP2pRssi[1]}
	fi

	if [ "$NOISEA" -gt "$NOISEB" ] ; then
		maxNoise=$NOISEA
	else
		maxNoise=$NOISEB
	fi

	# update noise property
	setprop 'wifi.ro.wlan0.noise' $maxNoise

	if [ "$P2PNOISEA" -gt "$P2PNOISEB" ] ; then
		maxP2pNoise=$P2PNOISEA
	else
		maxP2pNoise=$P2PNOISEB
	fi

	if [[ "$maxRssi" -ne 0 && "$maxNoise" -ne 0 ]] ; then
		maxSnr=$(($maxRssi - $maxNoise))
	fi

	if [[ "$maxP2pRssi" -ne 0 && "$maxP2pNoise" -ne 0 ]] ; then
		maxP2pSnr=$(($maxP2pRssi - $maxP2pNoise))
	fi
}

function iwpriv_show_channel
{
	SHOW_CHANNEL=($($IWPRIV $WLAN_INTERFACE show Channel))
	CHANNEL=${SHOW_CHANNEL[2]}
}

function log_metrics_phymode
{
	if [ "$PHYMODE" ] ; then
		mode=${PHYMODE#802.*}
		mode=${mode%% *}
		# There's a bug where 5 GHz 11a is marked as 11g.
		if [[ "$mode" == "11g" && $CHANNEL -gt 14 ]] ; then
			mode="11a"
		fi
		logStr="$LOGSRC:$LOGNAME:WifiMode$mode=1;CT;1:NR"
		log -t $METRICSTAG $logStr

		width=${PHYMODE#* }
		width=${width%Mhz*}"MHz"
		logStr="$LOGSRC:$LOGNAME:ChannelBandwidth$width=1;CT;1:NR"
		log -t $METRICSTAG $logStr
	fi
}

function log_metrics_rssi
{
	# dev rssi
	if [ "$maxRssi" -eq 0 ]; then
		return 0
	fi
	logStr="$LOGSRC:$LOGNAME:RssiLevel$maxRssi=1;CT;1:NR"
	log -t $METRICSTAG $logStr
}

function log_metrics_p2p_rssi
{
	# p2p rssi
	if [ "$maxP2pRssi" -eq 0 ]; then
		return 0
	fi
	logStr="$LOGSRC:$LOGNAME:P2PRssiLevel$maxP2pRssi=1;CT;1:NR"
	log -t $METRICSTAG $logStr
}

function log_metrics_snr
{
	# dev snr
	if [ "$maxSnr" ]; then
		logStr="$LOGSRC:$LOGNAME:SnrLevel$maxSnr=1;CT;1:NR"
		log -t $METRICSTAG $logStr
	fi
}

function log_metrics_p2p_snr
{
	# p2p snr
	if [ "$maxP2pSnr" ]; then
		logStr="$LOGSRC:$LOGNAME:P2PSnrLevel$maxP2pSnr=1;CT;1:NR"
		log -t $METRICSTAG $logStr
	fi
}

function log_metrics_noise
{
	# dev noise
	if [ "$maxNoise" -eq 0 ]; then
		return 0
	fi
	logStr="$LOGSRC:$LOGNAME:NoiseLevel$maxNoise=1;CT;1:NR"
	log -t $METRICSTAG $logStr
}

function log_metrics_p2p_noise
{
	# p2p noise
	if [ "$maxP2pNoise" -eq 0 ]; then
		return 0
	fi
	logStr="$LOGSRC:$LOGNAME:P2PNoiseLevel$maxP2pNoise=1;CT;1:NR"
	log -t $METRICSTAG $logStr
}

function log_metrics_mcs
{
	#dev mcs
	mcs=${LASTRXRATE/,*/}
	if [ "$mcs" ] ; then
		logStr="$LOGSRC:$LOGNAME:$mcs=1;CT;1:NR"
		log -t $METRICSTAG $logStr
	fi
}

function log_metrics_p2p_mcs
{
	#p2p mcs
	p2pMcs=${P2PLASTRXRATE/,*/}
	if [ "$p2pMcs" ] ; then
		logStr="$LOGSRC:$LOGNAME:P2P$p2pMcs=1;CT;1:NR"
		log -t $METRICSTAG $logStr
	fi
}

function log_connstatus_metrics
{
	if [[ $CONN_STATUS = "Connected" ]]; then
		logStr="$LOGSRC:$LOGNAME:ConnStatusConnected=1;CT;1;NR"
	elif [[ $CONN_STATUS = "Disconnected" ]]; then
		logStr="$LOGSRC:$LOGNAME:ConnStatusDisconnected=1;CT;1;NR"
	else
		logStr="$LOGSRC:$LOGNAME:ConnStatusOther=1;CT;1;NR"
	fi
	log -t $METRICSTAG $logStr
}

function log_wifi_metrics
{
	log_metrics_rssi
	log_metrics_snr
	log_metrics_noise
	log_metrics_mcs
	log_metrics_phymode
}

function log_p2p_metrics
{
	log_metrics_p2p_rssi
	log_metrics_p2p_snr
	log_metrics_p2p_noise
	log_metrics_p2p_mcs
}

function log_logcat
{
	logStr="$LOGNAME:rssi=$maxRssi;noise=$maxNoise;p2prssi=$maxP2pRssi;p2pnoise=$maxP2pNoise;channel=$CHANNEL;"
	logStr=$logStr"txframes=$TXFRAMES;txretries=$TXRETRIES;txper=$TXPER;txnoack=$TXRETRYNOACK;txplr=$TXPLR;"
	logStr=$logStr"rxframes=$RXFRAMES;rxcrc=$RXCRC;rxper=$RXPER;rxdrop=$RXDROP;rxdup=$RXDUP;"
	logStr=$logStr"falsecca=$TOTALCCA;onesecfalsecca=$ONECCA;"
	logStr=$logStr"phymode=$PHYMODE;phyrate=$PHYRATE;lasttxrate=$LASTTXRATE;lastrxrate=$LASTRXRATE;"
	logStr=$logStr"p2plasttxrate=$P2PLASTTXRATE;p2plastrxrate=$P2PLASTRXRATE"
	log -t $LOGCATTAG $logStr

	log_maxmin_signals
}

# Log the maximum and minimum values regarding signal quality
function log_maxmin_signals
{
	if [[ ! "$PREVIOUS_CHANNEL" ]] ; then
		PREVIOUS_CHANNEL=$CHANNEL
	elif [[ $PREVIOUS_CHANNEL != $CHANNEL ]] ; then
		PREVIOUS_CHANNEL=$CHANNEL
		MAX_RSSI=''
		MIN_RSSI=''
		MAX_NOISE=''
		MIN_NOISE=''
		MAX_P2P_RSSI=''
		MIN_P2P_RSSI=''
		MAX_P2P_NOISE=''
		MIN_P2P_NOISE=''
	fi

	if [[ ! "$MAX_RSSI" && ! "$MIN_RSSI" && ! "$maxRssi" -eq 0 ]] ; then
		MAX_RSSI=$maxRssi
		MIN_RSSI=$maxRssi
	fi

	if [[ ! "$MAX_NOISE" && ! "$MIN_NOISE" && ! "$maxNoise" -eq 0 ]] ; then
		MAX_NOISE=$maxNoise
		MIN_NOISE=$maxNoise
	fi

	if [[ ! "$MAX_P2P_RSSI" && ! "$MIN_P2P_RSSI" && ! "$maxP2pRssi" -eq 0 ]] ; then
		MAX_P2P_RSSI=$maxP2pRssi
		MIN_P2P_RSSI=$maxP2pRssi
	fi

	if [[ ! "$MAX_P2P_NOISE" && ! "$MIN_P2P_NOISE" && ! "$maxP2pNoise" -eq 0 ]] ; then
		MAX_P2P_NOISE=$maxP2pNoise
		MIN_P2P_NOISE=$maxP2pNoise
	fi

	if [ ! $maxRssi -eq 0 ] ; then
		if [ $maxRssi -gt $MAX_RSSI ] ; then
			MAX_RSSI=$maxRssi
		fi

		if [ $maxRssi -lt $MIN_RSSI ] ; then
			MIN_RSSI=$maxRssi
		fi
	fi

	if [ ! $maxNoise -eq 0 ] ; then
		if [ $maxNoise -gt $MAX_NOISE ] ; then
			MAX_NOISE=$maxNoise
		fi

		if [ $maxNoise -lt $MIN_NOISE ] ; then
			MIN_NOISE=$maxNoise
		fi
	fi

	if [ ! $maxP2pRssi -eq 0 ] ; then
		if [ $maxP2pRssi -gt $MAX_P2P_RSSI ] ; then
			MAX_P2P_RSSI=$maxP2pRssi
		fi

		if [ $maxP2pRssi -lt $MIN_P2P_RSSI ] ; then
			MIN_P2P_RSSI=$maxP2pRssi
		fi
	fi

	if [ ! $maxP2pNoise -eq 0 ] ; then
		if [ $maxP2pNoise -gt $MAX_P2P_NOISE ] ; then
			MAX_P2P_NOISE=$maxP2pNoise
		fi

		if [ $maxP2pNoise -lt $MIN_P2P_NOISE ] ; then
			MIN_P2P_NOISE=$maxP2pNoise
		fi
	fi

	logStr="$LOGNAME:max_rssi=$MAX_RSSI;min_rssi=$MIN_RSSI;max_noise=$MAX_NOISE;min_noise=$MIN_NOISE;"
	logStr=$logStr"max_p2prssi=$MAX_P2P_RSSI;min_p2prssi=$MIN_P2P_RSSI;max_p2pnoise=$MAX_P2P_NOISE;min_p2pnoise=$MIN_P2P_NOISE;"
	log -t $LOGCATTAG $logStr
}

function clear_stale_stats
{
	RSSI=""
	P2PRSSI=""
	SNRA=""
	SNRB=""
	P2PSNRA=""
	P2PSNRB=""
	NOISEA=""
	NOISEB=""
	P2PNOISEA=""
	P2PNOISEB=""
	LASTRXRATE=""
	P2PLASTRXRATE=""
	PHYMODE=""

	HADLASTRXRATE=0
	HADLASTTXRATE=0
	HADPHYRATE=0
	HADRSSI=0

	$IWPRIV $WLAN_INTERFACE set ResetCounter=1
}

function run ()
{
	set_wlan_interface

	if [[ -n $WLAN_INTERFACE ]]; then
		iwpriv_show_channel
		iwpriv_stat_tokens
		get_max_signal_stats
		log_logcat

		if [[ $currentLoop -eq $LOOPSTILMETRICS ]] ; then
			iwpriv_conn_status

			if [[ $CONN_STATUS = "Connected" ]]; then
				log_wifi_metrics
			fi
			log_p2p_metrics
			log_connstatus_metrics
			currentLoop=0
		else
			((currentLoop++))
		fi

		clear_stale_stats
	fi
}


# Run the collection repeatedly, pushing all output through to the metrics log.
while true ; do
	run
	sleep $DELAY
done
