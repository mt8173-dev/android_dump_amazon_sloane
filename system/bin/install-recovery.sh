#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery:16801792:059c3c5e399c1e8c0ec47de1ec85d342097074b4; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/mtk-msdc.0/by-name/boot:16001024:836679ede914a2e4dd4bda576d2f15d7816d2e4e EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery 059c3c5e399c1e8c0ec47de1ec85d342097074b4 16801792 836679ede914a2e4dd4bda576d2f15d7816d2e4e:/system/recovery-from-boot.p && echo "
Installing new recovery image: succeeded
" >> /cache/recovery/log || echo "
Installing new recovery image: failed
" >> /cache/recovery/log
else
  log -t recovery "Recovery image already installed"
fi
