#!/system/bin/sh
input="/data/idme.csv"

if [ ! -f $input ]; then
	exit
fi

while IFS="," read board_id board_id_val \
	serial serial_val \
	mac_addr mac_addr_val \
	mac_sec mac_sec_val \
	bt_mac_addr bt_mac_addr_val \
	product_name product_name_val \
	productid productid_val \
	productid2 productid2_val \
	bootmode bootmode_val \
	postmode postmode_val \
	bootcount bootcount_val \
	manufacturing manufacturing_val \
	eth_mac_addr eth_mac_addr_val \
	device_type_id device_type_id_val
do
	/system/xbin/idme $board_id $board_id_val
	/system/xbin/idme $serial $serial_val
	/system/xbin/idme $mac_addr $mac_addr_val
	/system/xbin/idme $mac_sec $mac_sec_val
	/system/xbin/idme $bt_mac_addr $bt_mac_addr_val
	/system/xbin/idme $product_name $product_name_val
	/system/xbin/idme $productid $productid_val
	/system/xbin/idme $productid2 $productid2_val
	/system/xbin/idme $bootmode $bootmode_val
	/system/xbin/idme $postmode $postmode_val
	/system/xbin/idme $bootcount $bootcount_val
	/system/xbin/idme $manufacturing $manufacturing_val
	/system/xbin/idme $eth_mac_addr $eth_mac_addr_val
	/system/xbin/idme $device_type_id $device_type_id_val
done < "$input"

if [ -f $input ]; then
	rm $input
fi



