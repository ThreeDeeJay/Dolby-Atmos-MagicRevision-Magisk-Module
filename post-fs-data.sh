mount -o rw,remount /data
MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml
ACDB=/data/adb/modules/acdb

# debug
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# context
if [ "$API" -ge 26 ]; then
  chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
fi

# etc
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi
ETC=$MAGISKTMP/mirror/system/etc
VETC=$MAGISKTMP/mirror/system/vendor/etc
VOETC=$MAGISKTMP/mirror/system/vendor/odm/etc
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc

# conflict
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& [ -d $ACDB ] && [ ! -f $ACDB/disable ]; then
  touch $ACDB/disable
fi

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# audio files
NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
NAME2="*audio*effects*.conf -o -name *audio*effects*.xml"
NAME3="*policy*.conf -o -name *policy*.xml"
rm -f `find $MODPATH/system -type f -name $NAME`
AE=`find $ETC -maxdepth 1 -type f -name $NAME2`
VAE=`find $VETC -maxdepth 1 -type f -name $NAME2`
AP=`find $ETC -maxdepth 1 -type f -name $NAME3`
VAP=`find $VETC -maxdepth 1 -type f -name $NAME3`
VOA=`find $VOETC -maxdepth 1 -type f -name $NAME`
VAA=`find $VETC/audio -maxdepth 1 -type f -name $NAME`
VBA=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME`
if [ ! -d $ACDB ] || [ -f $ACDB/disable ]; then
  if [ "$AE" ]; then
    cp -f $AE $MODETC
  fi
  if [ "$VAE" ]; then
    cp -f $VAE $MODVETC
  fi
fi
if [ "$AP" ]; then
  cp -f $AP $MODETC
fi
if [ "$VAP" ]; then
  cp -f $VAP $MODVETC
fi
if [ "$VOA" ]; then
  cp -f $VOA $MODVOETC
fi
if [ "$VAA" ]; then
  cp -f $VAA $MODVETC/audio
fi
if [ "$VBA" ]; then
  cp -f $VBA $MODVETC/audio/"$PROP"
fi
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSA=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME`
    if [ "$VSA" ]; then
      cp -f $VSA $MODVETC/audio/$SKUS
    fi
  done
fi
rm -f `find $MODPATH/system -type f -name *policy*volumes*.xml`

# run
sh $MODPATH/.aml.sh

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  sh $FILE
  rm -f $FILE
fi


