#!/bin/sh

# Auther: exa
# Date: 20160525

##
# set Env
#
# Import CSV Format "IPADDRESS,SNMP_Port,SNMP_CommunityName,"
# Export CSV Format "IPADDRESS,SNMP_Port,SNMP_CommunityName,PingStatus,SNMPStatus,FQDN"
#

IP_LIST=$1

DATE=`date +%Y%m%d-%H%M%S`           # Getting current date

# Directory
CURRENTDIR=`/bin/pwd`

# Command
PING="/bin/ping"
PINGOPTIONS="-c 1 -w 3 " # for Linux

SNMPGET="/usr/bin/snmpget"
SNMPTIMEOUT="0.1"
FQDNCheck="$CURRENTDIR/ip2fqdn.pl "



if [ "${IP_LIST}" = "" ]; then
  echo "第一引数にIPアドレスリストのファイル名を指定してください"
  exit 1
fi
if [ ! -f ${IP_LIST} ]; then
  echo "第一引数に指定したファイルが存在しません"
  exit 1
fi


echo "------- PingCheck $DATE ------------- "
echo "ADDRESS,SNMP_Port,SNMP_Community,PingSTATUS,SNMPStatus,FQDN"
#echo "ADDRESS,STATUS,FQDN"

while read LINE
    do
	# PingCheck
	ADDRESS=`echo $LINE | cut -d',' -f1`
        $PING $PINGOPTIONS $ADDRESS > /dev/null 2>&1
        if [ $? == 0 ];
        then
	    PingStatus="OK"
        else
	    PingStatus="NG"
        fi
	if [ $PingStatus = "OK" ];then
	    # SNMPCheck
	    SNMP_PORT=`echo $LINE | cut -d',' -f2`
	    COMMUNITY=`echo $LINE | cut -d',' -f3`
            SNMP_sysName=`$SNMPGET -t $SNMPTIMEOUT -v 1 -c $COMMUNITY $ADDRESS:$SNMP_PORT .1.3.6.1.2.1.1.5.0 > /dev/null 2>&1`
            if [ $? == 0 ];
            then
	        SNMPStatus="OK"
            else
	        SNMPStatus="NG"
            fi
	else
		SNMPStatus="NaN"
	fi

	# FQDN Check
        FQDN=`$FQDNCheck $ADDRESS`

	echo "$ADDRESS,$SNMP_PORT,$COMMUNITY,$PingStatus,$SNMPStatus,$FQDN,"

    done < ${IP_LIST}

exit 0



