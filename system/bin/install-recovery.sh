#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery:16809984:20cdf2758c277118218e0efc0a57ef27856fb4c4; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/mtk-msdc.0/by-name/boot:16009216:9f6014bb8bd543c6472ed3b83c5829876e89ba37 EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery 20cdf2758c277118218e0efc0a57ef27856fb4c4 16809984 9f6014bb8bd543c6472ed3b83c5829876e89ba37:/system/recovery-from-boot.p && echo "
Installing new recovery image: succeeded
" >> /cache/recovery/log || echo "
Installing new recovery image: failed
" >> /cache/recovery/log
else
  log -t recovery "Recovery image already installed"
fi
