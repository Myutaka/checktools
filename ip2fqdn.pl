#!/usr/bin/perl
use Socket;

if (@ARGV == 0) {
    $ipaddress = "localhost";
}elsif (@ARGV == 1 ){
    $ipaddress = $ARGV[0];
} else {
 die "Usage : $myName ipaddress \n";
}

$host = gethostbyaddr(pack("C4", split(/\./, $ipaddress)), 2);

printf ("%s\n",$host);

