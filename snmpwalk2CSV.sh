#/bin/bash

# Auther: Miyata
# Date: 20100525
# Mod: 20160716
# Usage:  sanmpwalk2CSV.sh [コンフィグファイル名]
#         引数が無い場合は、シェルと同一ディレクトリにあるsnmpwalk2CSV.cfg
#         ファイルを読み込む
#         -c オプションでコンフィグファイルを指定可能
# DESCRIPTION:
#   LocalホストのSNMPエージェントの任意のTable形式の1つのObjectに対し、
#   snmpwalkを実行し、カンマ区切りの1行に出力する。
# 制約:
#   snmpwalk結果に"改行コード"や、"半角スペース"が含まれていないこと。
#   取得対象のObjectは、net-snmpでパーズできる環境であること。
#     net-snmpの仕様により、RFC1213以外のObjectの場合、snmpwalk対象Object名は、MIB名::Object名
#     と記述する。
#   ObjectのIndexは、1段階であること(2段階以上のIndexは、Index処理が別に必要になる。
#
# Export CSV Format "ObjectName,[Index],[Index],...."
#                   "UNIXTIME,[Value],[Value],...."
#
### ConfigFile に設定してある変数
# PING="/bin/ping"
# PINGOPTIONS="-c 1 -w 1 " # for Linux
# 
# SNMPWALK="/usr/bin/snmpwalk"
# SNMPVERSION="1"
# SNMPTIMEOUT="0.5"
# SNMPCOMMUNITY="public"
# SNMPMIBDIR="/opt/netcool/ssm/mibs/"
# WALKIDXTITLE="ifDescr"
# WALKIDX="ifDescr"
# WALKOID="ifInOctets"
#
## DefValue
# ADDRESS=localhost
# SNMP_PORT=161
# CSVFILE="/tmp/snmpwalk2CSV.csv"
# ERRLOG="/tmp/snmpwalk2CSV.log"


# シェル実行ディレクトリの取得
SHELLDIR=$(cd $(dirname $0);pwd)

# デフォルトコンフィグファイル名 の定義
DEFConfFile="snmpwalk2CSV.cfg"


# 引数のチェック
ARG=$1
if [ "${ARG}" = "" ]; then
#  echo "引数がなければ、デフォルトのコンフィグファイルを読み込む"
  VALUE_C="$SHELLDIR/$DEFConfFile"
  :
elif [ $ARG != "-c" ]; then
  echo "Usage:  ${0##*/} [-c ConfigFile]"
#  echo "一個めの引数が、-c 以外はNG"
  exit 1
elif [ $# = 2 ]; then
#  echo "引数が2個の場合は、getopts処理に回す"
# 引数 -c の処理
  while getopts c: OPT
  do
    case $OPT in
        "c" ) FLG_C="TRUE" ; VALUE_C="$OPTARG" ;;
          * ) echo "Usage:  ${0##*/} [-c ConfigFile]"
              exit 1 ;;
    esac
  done
  :
else
   echo "Usage:  ${0##*/} [-c ConfigFile]"
#  echo "引数が 0 か 2個以外は終了"
  exit 1
fi

# コンフィグファイルの存在確認読み込み
if [ ! -f $VALUE_C ]; then
    echo "引数に指定したファイルが存在しません"
    exit 1
else
#    echo "コンフィグファイルの読み込み"
    source $VALUE_C
fi


# 出力用CSVファイルの存在チェック
# 存在していれば FileFLG=1 ,存在していなければ FileFLG=0 をセット
if [ ! -e $CSVFILE ]; then
#    echo "$CSVFILE  is Not Exist"
    FileFLG=0
else
#    echo "$CSVFILE is Exist"
    FileFLG=1
fi

# ファイルのサイズチェック
# サイズが"0"以外であれば FileFLG=1 ,"0"であれば FileFLG=0 をセット
if [ -s $CSVFILE ]; then
#    echo "$CSVFILE   FileSize != 0"
    FileFLG=1
else
#    echo "$CSVFILE  FileSize = 0"
    FileFLG=0
fi

# Ping応答の確認
#  -> 今回は不要

#
# SNMPwalk実行 Indexデータの取得と、出力処理
#   出力用CSVファイルが存在していなかった場合の処理
#
if [ $FileFLG == 0 ]; then
    # 出力用CSVファイルが0バイトor存在しないため、Index情報を出力
    # SNMPWALKINDEX=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $WALKIDX 2>/dev/null`
    SNMPWALKINDEX=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $WALKIDX 2>>$ERRLOG `
    if [ $? != 0 ]; then
      SNMPStatus="NG"
      DATE=`date +%Y/%m/%d-%H:%M:%S`
      echo " $DATE [ERROR] SNMP Not Responce" >> $ERRLOG
      exit 1
#    else
#      SNMPStatus="OK"
    fi

    # CSVファイルにデータを出力
    SNMPIDXArr=()
    SNMPIDXArr+=("$WALKIDXTITLE")
    SNMPIDXArr+=($SNMPWALKINDEX)
    SNMPIDXArrData=${SNMPIDXArr[@]}
    # 配列格納情報を出力し、デリミタを "半角スペース" から "カンマ" に置換して出力
    echo ${SNMPIDXArrData// /,} >> $CSVFILE
fi

#
# SNMPwalk実行 値取得用snmpwalkデータの取得と出力処理
#

# 配列の最初のデータとしてUNIXTIMEフォーマットマットで実行時時間を挿入
#SNMPDATAArr+=(`date +%s`)
# 配列の最初のデータとしてYYMMDD-hh:mm:ssフォーマットで実行時間挿入
SNMPDATAArr=()
SNMPDATAArr+=(`date +%Y/%m/%d-%H:%M:%S`)

# Table形式のObjectの値のみを格納  snmpwalkのオプションに -Ovq を指定
#SNMPWALKDATA=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $WALKOID 2>/dev/null`
SNMPWALKDATA=`$SNMPWALK -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $WALKOID 2>>$ERRLOG`
if [ $? != 0 ];
then
    SNMPStatus="NG"
#   echo "[ERROR] SNMP Not Responce"
    SNMPDATAArr+=("NaN")
else
    SNMPStatus="OK"

    # 配列に格納してあるデータのCSV形式への出力確認
    # 配列格納情報を出力し、デリミタを "半角スペース" から "カンマ" に置換して出力
    SNMPDATAArr+=("$SNMPWALKDATA")
    SNMPDATAArrData=${SNMPDATAArr[@]}
    echo ${SNMPDATAArrData// /,} >> $CSVFILE
fi
        
exit 0
