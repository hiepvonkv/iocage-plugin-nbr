#!/bin/sh

PRODUCT='NAKIVO Backup & Replication'
URL="http://10.8.80.22:8081/NAKIVO_Backup_Replication_v11.1.0.94430_Installer-TRIAL.sh"
SHA256="af5f58cc1b9bb4b2e272564873e3ec36b9d86616ebb2471d1d32e2f3df9e46ef"

PRODUCT_ROOT="/usr/local/nakivo"
INSTALL="inst.sh"

curl --fail --tlsv1.2 -o $INSTALL $URL
if [ $? -ne 0 -o ! -e $INSTALL ]; then
    echo "ERROR: Failed to get $PRODUCT installer"
    rm $INSTALL >/dev/null 2>&1
    exit 1
fi

# CHECKSUM=`sha256 -q $INSTALL`
# if [ "$SHA256" != "$CHECKSUM" ]; then
#     echo "ERROR: Incorrect $PRODUCT installer checksum"
#     rm $INSTALL >/dev/null 2>&1
#     exit 2
# fi

sh ./$INSTALL -f -y -i "$PRODUCT_ROOT" --eula-accept --extract
if [ $? -ne 0 ]; then
    echo "ERROR: $PRODUCT install failed"
    rm $INSTALL >/dev/null 2>&1
    exit 3
fi
rm $INSTALL >/dev/null 2>&1

#disable default HTTP ports redirect
SVC_PATH="$PRODUCT_ROOT/director"
awk 'BEGIN{A=0} /port="80/{A=1} {if (A==0) print $0} />/{A=0}' $SVC_PATH/tomcat/conf/server-linux.xml >$SVC_PATH/tomcat/conf/server-linux.xml_ 2>/dev/null
mv $SVC_PATH/tomcat/conf/server-linux.xml_ $SVC_PATH/tomcat/conf/server-linux.xml >/dev/null 2>&1

#enforce EULA
PROFILE=`ls "$SVC_PATH/userdata/"*.profile 2>/dev/null | head -1`
if [ "x$PROFILE" != "x" ]; then
    sed -e 's@"system.licensing.eula.must.agree": false@"system.licensing.eula.must.agree": true@' "$PROFILE" >"${PROFILE}_" 2>/dev/null
    mv "${PROFILE}_" "$PROFILE" >/dev/null 2>&1
fi

service nkv_dirsvc start >/dev/null 2>&1
