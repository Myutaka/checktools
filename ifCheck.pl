#!/usr/bin/perl
use Net::Ping;
#
$snmpsocketnum=10161;
#


if (@ARGV == 1) {
    $hostlist = $ARGV[0];
} else {
 die "Usage : $myName hostnamefile \n";
}

open (FILE,$hostlist) || die " Can not Open file $hostlist \n" ;

while (<FILE>){
	chomp;
	@item = split /\,/;

# Write File Open
	open(OUT,">> $item[3].txt");

#	printf ("%s,%s",$item[0],$item[1]);
	print OUT "--------------------------------------------------------\n";
	print OUT "$item[1]\n";

# PingCheck
	$timeout = 1;
	$pObj=Net::Ping->new("icmp");

	if($pObj->ping($item[1],$timeout)){
		$pingFlg=1;
		print OUT "$item[1] PingOK\n";
	}else{
		$pingFlg=0;
		print OUT "$item[1] PingNG\n";
	}
	$pObj->close();


	if( $pingFlg==1){
	print OUT "SOS Name is $item[3]. \n";
	print OUT "Start SNMP Requeest. \n";
	print OUT "system group \n";
	$snmpsystemData=`/usr/bin/snmpwalk -v 2c -c public $item[1]:$item[0] .1.3.6.1.2.1.1`;
	print OUT "$snmpsystemData\n\n";
	print OUT "iftable \n";
	$snmpifData=`/usr/bin/snmptable -v 2c -c public $item[1]:$item[0] -Cf , ifTable`;
	print OUT "$snmpifData\n\n";
	print OUT "ifXtable \n";
	$snmpifXData=`/usr/bin/snmptable -v 2c -c public $item[1]:$item[0] -Cf , ifXTable`;
	print OUT "$snmpifXData\n\n";
	print OUT "iptable \n";
	$snmpipData=`/usr/bin/snmptable -v 2c -c public $item[1]:$item[0] -Cf , ipAddrTable`;
	print OUT "$snmpipData\n\n";
	$snmpNet2MediaData=`/usr/bin/snmptable -v 2c -c public $item[1]:$item[0] -Cf , ipNetToMediaTable`;
	print OUT "$snmpNet2MediaData\n\n";


	close OUT;
	
	}



#	print "     $item[1] \n";
	
	print "\n";
}

close FILE;

