#/bin/bash

# Auther: Miyata
# Date: 20100525
# Mod: 20160716
# Usage:  sanmpget2CSV.sh [コンフィグファイル名]
#         引数が無い場合は、シェルと同一ディレクトリにあるsnmpget2CSV.cfg
#         ファイルを読み込む
#         -c オプションでコンフィグファイルを指定可能
# DESCRIPTION:
#   LocalホストのSNMPエージェントの任意のScolar形式の1つのObjectに対し、
#   snmpgetを実行し、カンマ区切りの1行に出力する。
# 制約:
#   snmpget結果に"改行コード"や、"半角スペース"が含まれていないこと。
#   取得対象のObjectは、net-snmpでパーズできる環境であること。
#     net-snmpの仕様により、RFC1213以外のObjectの場合、snmpget対象Object名は、MIB名::Object名
#     と記述する。
#
# Export CSV Format "ObjectName,ObjectName"
#                   "UNIXTIME,[Value]"
#
### ConfigFile に設定してある変数
# PING="/bin/ping"
# PINGOPTIONS="-c 1 -w 1 " # for Linux
#
# SNMPGET="/usr/bin/snmpget"           # net-snmp のsnmpgetコマンドのパスを記述
# SNMPVERSION="1"                      # 指定可能なオプションは 1 or 2c 
# SNMPTIMEOUT="0.5"                    # snmpgetコマンドのタイムアウト
# SNMPCOMMUNITY="public"               # snmpgetコマンドのコミュニティ名
# SNMPMIBDIR="/opt/netcool/ssm/mibs/"  # snmpcmd コマンドの -M オプションで指定する MIBディレクトリ
# GETTITLE="ipInReceives"              # CSV出力ファイルのインデックスタイトル名
# GETIDX="ipInReceives"                # CSV出力ファイルのインデックス名
# GETOID="ipInReceives.0"              # CSV出力ファイルの取得MIB名(Scolar形式のみ)
#
## 
# ADDRESS=localhost
# SNMP_PORT=10161
# CSVFILE="/tmp/2snmpget2CSV.csv"
# ERRLOG="/tmp/2snmpget2CSV.errlog"   # snmpget の エラーログ



# シェル実行ディレクトリの取得
SHELLDIR=$(cd $(dirname $0);pwd)

# デフォルトコンフィグファイル名 の定義
DEFConfFile="snmpget2CSV.cfg"


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
# タイトル行の出力処理
#   出力用CSVファイルが存在していなかった場合の処理
#
if [ $FileFLG == 0 ]; then
    # CSVファイルにデータを出力
    SNMPIDXArr=()
    SNMPIDXArr+=("$GETTITLE")
    SNMPIDXArr+=("$GETIDX")
    SNMPIDXArrData=${SNMPIDXArr[@]}
    # 配列格納情報を出力し、デリミタを "半角スペース" から "カンマ" に置換して出力
    echo ${SNMPIDXArrData// /,} >> $CSVFILE
fi

#
# SNMPget実行 値取得用snmpgetデータの取得と出力処理
#

# 配列の最初のデータとしてUNIXTIMEフォーマットマットで実行時時間を挿入
#SNMPDATAArr+=(`date +%s`)
# 配列の最初のデータとしてYYMMDD-hh:mm:ssフォーマットで実行時間挿入
SNMPDATAArr=()
SNMPDATAArr+=(`date +%Y/%m/%d-%H:%M:%S`)

# Table形式のObjectの値のみを格納  snmpgetのオプションに -Ovq を指定
#SNMPGETDATA=`$SNMPGET -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $GETOID 2>/dev/null`
SNMPGETDATA=`$SNMPGET -t $SNMPTIMEOUT -v $SNMPVERSION -c $SNMPCOMMUNITY -m all -M $SNMPMIBDIR -Ovq $ADDRESS:$SNMP_PORT $GETOID 2>>$ERRLOG`
if [ $? != 0 ];
then
    SNMPStatus="NG"
#   echo "[ERROR] SNMP Not Responce"
    SNMPDATAArr+=("NaN")
else
    SNMPStatus="OK"

    # 配列に格納してあるデータのCSV形式への出力確認
    # 配列格納情報を出力し、デリミタを "半角スペース" から "カンマ" に置換して出力
    SNMPDATAArr+=("$SNMPGETDATA")
    SNMPDATAArrData=${SNMPDATAArr[@]}
    echo ${SNMPDATAArrData// /,} >> $CSVFILE
fi
        
exit 0
