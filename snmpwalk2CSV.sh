#/bin/sh

# Auther: exa
# Date: 20160525
# DESCRIPTION:
#   LocalホストのSNMPエージェントの任意のTable形式の1つのObjectに対し、
#   snmpwalを実行し、カンマ区切りの1行に出力する。
# 制約:
#   snmpwalk結果に"改行コード"や、"半角スペース"が含まれていないこと。
#   取得対象のObjectは、net-snmpでパーズできる環境であること。
#     net-snmpの仕様により、RFC1213以外のObjectの場合、snmpwalk対象Object名は、MIB名::Object名
#     と記述する。
#   ObjectのIndexは、1段階であること(2段階以上のIndexは、Index処理が別に必要になる。
#

#
# set Env
#
# Import CSV Format "IPADDRESS,SNMP_Port,SNMP_CommunityName,IndexTitle,IndexObject,ObjectName"
#
# Export CSV Format "ObjectName,[Index],[Index],...."
#                   "UNIXTIME,[Value],[Value],...."
#

IP_LIST=$1

DATE=`date +%s`           # Getting current date UNIXTIME

# Directory
CURRENTDIR=`/bin/pwd`


# Command
PING="/bin/ping"
PINGOPTIONS="-c 1 -w 1 " # for Linux

SNMPWALK="/usr/bin/snmpwalk"
SNMPVERSION="1"
SNMPTIMEOUT="0.5"
SNMPCOMMUNITY="public"
SNMPMIBDIR="/opt/netcool/ssm/mibs/"
WALKIDXTITLE="ifDescr"
WALKIDX="ifDescr"
WALKOID="ifInOctets"

# DefValue
ADDRESS=localhost
SNMP_PORT=161
CSVFILE="/tmp/walk2csv.csv"


# 引数のチェック
if [ "${IP_LIST}" = "" ]; then
  echo "第一引数にIPアドレスリストのファイル名を指定してください"
  exit 1
fi
if [ ! -f ${IP_LIST} ]; then
  echo "第一引数に指定したファイルが存在しません"
  exit 1
fi

# ファイルの存在チェック
# 存在していれば FileFLG=1 ,存在していなければ FileFLG=0 をセット
LogFile=/tmp/snmpwalk.log
if [ ! -e $LogFile ]; then
#    echo "$LogFile  is Not Exist"
    FileFLG=0
else
#    echo "$LogFile is Exist"
    FileFLG=1
fi

# ファイルのサイズチェック
# サイズが"0"以外であれば FileFLG=1 ,"0"であれば FileFLG=0 をセット
if [ ! -s $LogFile ]; then
    echo "$LogFile   FileSize != 0"
    FileFLG=1
else
    echo "$LogFile  FileSize = 0"
    FileFLG=0
fi


#
# 引数のファイルに記載されている値を各変数に格納
#
while read LINE
    do
        ADDRESS=`echo $LINE | cut -d',' -f1`
        SNMP_PORT=`echo $LINE | cut -d',' -f2`
        COMMUNITY=`echo $LINE | cut -d',' -f3`
        WALKIDXTITLE==`echo $LINE | cut -d',' -f4`
        WALKIDX=`echo $LINE | cut -d',' -f5`
        WALKOID=`echo $LINE | cut -d',' -f6`

        #
        # Ping応答の確認
        #  -> 今回は不要

        #
        # SNMPwalk実行 Indexデータの取得
        #
        SNMPWALKINDEX=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $COMMUNITY -m all -M $SNMPMIBDIR $ADDRESS:$SNMP_PORT $WALKIDX > /dev/null 2>&1`
        if [ $? != 0 ];
        then
            SNMPStatus="NG"
            echo "[ERROR] SNMP Not Responce"
            echo "[ERROR] SNMP Not Responce" >> $CSVFILE
            exit
        else
            SNMPStatus="OK"
        fi

        SNMPIDXArr=()
        SNMPIDXArr+=("$WALKIDXTITLE")
        SNMPIDXArr+=($SNMPWALKINDEX)

        #
        # SNMPwalk実行 walkデータの取得
        #

        # 配列の最初のデータとしてUNIXTIMEを挿入
        SNMPDATAArr+=(`date +%s`)

        SNMPWALKDATA=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $COMMUNITY -m all -M $SNMPMIBDIR $ADDRESS:$SNMP_PORT $WALKOID > /dev/null 2>&1`
        if [ $? != 0 ];
        then
            SNMPStatus="NG"
            echo "[ERROR] SNMP Not Responce"
            echo "NaN" >> $CSVFILE
        else
            SNMPStatus="OK"
        fi
        
        SNMPDATAArr+=("$SNMPWALKDATA")



        # 配列に格納してあるデータのCSV形式への出力確認
        # 配列格納情報を出力し、デリミタを "半角スペース" から "カンマ" に痴漢して出力
        SNMPIDXArrData=${SNMPIDXArr[@]}
        echo ${SNMPIDXArrData// /,}
        
        SNMPIDXArrData=${SNMPIDXArr[@]}
        echo ${SNMPIDXArrData// /,}
        
    done < ${IP_LIST}
exit
