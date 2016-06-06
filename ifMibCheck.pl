#!/usr/bin/perl

# Auther:YM
# Date:20160606

#use strict;
use warnings;
use File::Basename;
#
#
#
$myName = basename($0,'');

if (@ARGV == 1) {
    $hostlist = $ARGV[0];
} else {
 die "Usage : $myName IPList \n";
}

$DATE=`date +%Y%m%d-%H%M%S`;
$currentDIR=`/bin/pwd`;
chomp($currentDIR);
$pingcmd="/bin/ping";
$pingOPTIONS=-"c 1 -w 1 ";
$snmpVersion="2c";
$snmptimeout="0.5";
$snmpCOMMUNITY="public";
$snmpGETcmd="/usr/bin/snmpget";
#$snmpWALKcmd="/usr/bin/snmpwalk";
$snmpTBLcmd="/usr/bin/snmptable";


open (FILE,$hostlist) || die " Can not Open file $hostlist \n" ;

while (<FILE>){
	chomp;
	@item = split /\,/;

# set ARG
	$ipaddress = $item[0];
	$snmpport = $item[1];
	$snmpCOMMUNITY = $item[2];


# Write File Open
	open(OUT,">> $currentDIR\/$ipaddress.txt");

        chomp($DATE);
	print OUT "---------------------$DATE-----------------------------\n";
	printf "----------------------$DATE----------------------------------\n";
	print OUT  "ipaddress \: $ipaddress,  snmpport \: $snmpport, community \: $snmpCOMMUNITY \n";
	printf  "ipaddress \: $ipaddress,  snmpport \: $snmpport, community \: $snmpCOMMUNITY \n";

# PingCheck
        $pingResult = "$pingcmd $pingOPTIONS $ipaddress > /dev/null 2>&1";

#	if( $pingResult eq ""){
	if( system( $pingResult ) ){
	print OUT "Ping Not Response \n";
	printf "Ping Not Response \n";
	} else {
	printf " Start SNMP Request\n";
# SNMP Response Check
        $snmpResult = "$snmpGETcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport -t $snmptimeout sysName.0 > /dev/null 2>&1";
	if( system( $snmpResult) ){
		print OUT " SNMP Not Response \n";
		printf " SNMP Not Response \n";
		} else {
# SNMP Check for ITNM Discovery

		print OUT "Start SNMP Requeest. \n";
		$snmpsysName=`$snmpGETcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport -Ovq sysName.0 `; # system .1.3.6.1.2.1.1`;
		$snmpsysDescr=`$snmpGETcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport -Ovq sysDescr.0 `; # system .1.3.6.1.2.1.1`;
		$snmpsysObjID=`$snmpGETcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport -Ovq sysObjectID.0 `; # system .1.3.6.1.2.1.1`;
		print OUT "sysName\n";
		print OUT "$snmpsysName\n";
		print OUT "sysDescr\n";
		print OUT "$snmpsysDescr\n";
		print OUT "sysObjectID\n";
		print OUT "$snmpsysObjID\n\n";

		print OUT "iftable \n";
		$snmpifData=`$snmpTBLcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport -Cf ,  ifTable `; # ifTable ifTable .1.3.6.1.2.1.2.2 ;
		print OUT "$snmpifData\n\n";
		print OUT "ifXtable \n";
		$snmpifXData=`$snmpTBLcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport  -Cf , ifXTable `; # ifXTable .1.3.6.1.2.1.31.1.1;
		print OUT "$snmpifXData\n\n";
		print OUT "ipTable \n";
		$snmpipData=`$snmpTBLcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport  -Cf , ipAddrTable `; # ipAddrTable .1.3.6.1.2.1.4.20;
		print OUT "$snmpipData\n\n";
		$snmpNet2MediaData=`$snmpTBLcmd -v $snmpVersion -c $snmpCOMMUNITY $ipaddress:$snmpport  -Cf , ipNetToMediaTable `; # ipNetToMediaTable .1.3.6.1.2.1.4.22;
		print OUT "$snmpNet2MediaData\n\n";

# dot1dBasePortTable .1.3.6.1.2.1.17.1.4.1

		printf " End of SNMP Response \n";
		}
	close OUT;
	}

	
	print "\n";
}

close FILE;

