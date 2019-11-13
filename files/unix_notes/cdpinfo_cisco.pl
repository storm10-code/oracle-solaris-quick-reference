#!/usr/bin/perl -w
# 
# Listen for Cisco Discovery Protocol (CDP) packets
# and print out key values such as switch, port and vlan.
#
# This script depends on either "snoop" (Solaris) or 
# "tcpdump" (Linux, AIX, and others).  Both of those programs generally 
# must be run as root.
#
# It has been tested on Solaris 10 and Linux (CentOS, Ubuntu)
#
#
# This work is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or any later
# version.
# This work is distributed in the hope that it will be useful, but without 
# any warranty; without even the implied warranty of merchantability or 
# fitness for a particular purpose. See version 2 and version 3 of the GNU
# General Public License for more details.
#
# Latest update: Dariusz Ankowski
# Version 1.2
# May 2008
#	Some code cleaning, this version works also on Linux.
#
# Original code: Andy Welter
# Version 1.1
# July 2007
# 	Support timeout values while waiting on the cdp packet.
# 
# Version 1.0
# December 2006
#	Initial Version.

use Getopt::Std;

my $cmd = undef;
my $idev;
my $verbose;
my $timeout=60;
my $temp_pkt=undef; # Workaround for tcpdump

our ($opt_h, $opt_i, $opt_t);

sub usage {
	print<<EOF;
Usage: $0 -i devX [-t tmout] [-v]
	-i devX   : Use the devX device name for the interface to watch.
	-t tmout  : Timeout value in seconds. Don't wait for a CDP packet longer than this.
                    Default is 60 seconds. 0 means no limit.
	-v        : Verbose output.
	-h        : This help message.
EOF

	exit 1;
}

sub timeout {
	die "TIMEOUT";
};

sub hexprint {
	(my $str = shift) =~ s/(.|\n)/sprintf("%02lx ", ord $1)/eg;
	return $str;
}

# Parse output for the packet
sub snoop {
	my ($cmd)=@_;
	my $packet=$temp_pkt;
	open (GETPACKET, "$cmd") || die "Cannot open $cmd\n";

	while ( $_ = <GETPACKET> ) {
		chomp;
		$verbose && print "--> $_\n";	
		if (s/^\s*[\dxa-fA-F]+:?\s+//) {
			@data=split /\s+/,$_,9;
			pop @data;
			foreach $bytes (@data) 	{
				$packet=$packet . pack "H4", $bytes;
			};
		};
	};
	close GETPACKET;

	return $packet;
};

# Parse the acquired CDP packet for key values.
sub decodePacket {
	# decode the packet
	# ethernet layout:
	# 0-7   8 byte preamble
	# 8-13  6 byte dest mac addr
	# 14-19 6 byte source mac addr
	# 20-21 2 byte type field
	# 22-23 2 byte check sum
	# 24-25 2 byte ???
	# 26-27 2 byte first CDP data field
	# 28-29 2 byte field length (including field type and length)
	# 30--  Variable data.
	#       4 byte CRC field.
	#
	# Field type indicators
	# Device-ID  => 0x01
	# Version-String  => 0x05
	# Platform  => 0x06
	# Address  => 0x02
	# Port-ID  => 0x03
	# Capability  => 0x04
	# VTP-Domain  => 0x09
	# VLAN-ID  => 0x0a
	# Duplex  => 0x0b
	# AVVID-Trust  => 0x12
	# AVVID-CoS  => 0x13);

	my ($packet)=@_;
	my ($plen,$string,$ii,$flength,$switchName,$switchPort,$ftype,$vlan) = undef;

	$verbose && printf "packet len=%d\n",length($packet);

	# The CDP packet data starts at offset 26
	$ii=26;
	$plen=length ($packet);
	while ( $ii < $plen-4) {
		$ftype=unpack "n", substr ($packet, $ii, 2);
		$flength=unpack "n", substr ($packet, $ii+2, 2);
		if ($ftype==1) {
			$switchName=substr ($packet,$ii+4,$flength-4);
		} elsif ($ftype==3) {
			$switchPort=substr ($packet,$ii+4,$flength-4);
		} elsif ($ftype==10) {
			$vlan=unpack "n",substr ($packet,$ii+4,$flength-4);
		}
		if ($verbose) {
			$string=substr ($packet,$ii+4,$flength-4);
			$fvalue=hexprint ($string);
			$string=~s/[[:^print:]]/./g;
			printf "\noffset=%d, type 0x%04x, length 0x%04x\nHex Value:\n%s\nASCII value:\n%s\n\n",
										$ii,$ftype, $flength-4,$fvalue,$string;
		}
		if ($flength == 0 ) {
			$ii=$plen;
		};
		$ii=$ii+$flength;
	};

	# Print results

	print "Switch: $switchName\n";
	print "Port:   $switchPort\n";
	print "VLAN:   $vlan\n";
};



# Check for parameters
getopts('vht:i:');

usage if defined $opt_h;
$timeout=$opt_t if defined $opt_t;
$verbose=$opt_v if defined $opt_v;
if (defined $opt_i) {
	$idev=$opt_i;
} else {
	usage;
}


#
# MAIN ROUTINE
#
# determine whether we are a snoop or tcpdump kinda system

$cmd=`which tcpdump 2>/dev/null`;
chomp $cmd;
if ( -x "$cmd" ) {
	$cmd="$cmd -i $idev -s 1500 -X -c 1 'ether [20:2] = 0x2000' 2>/dev/null |";
	$temp_pkt="01234567890123";
} else {
	$cmd=`which snoop 2>/dev/null`;
	chomp $cmd;
	if ( -x "$cmd" ) {
		$cmd="$cmd -d $idev -s 1500 -x0 -c 1 'ether[20:2] = 0x2000' 2>/dev/null |";
	} else {
		print "ERROR: neither snoop nor tcpdump in my path\n";
		exit 1;
	}
}

$SIG{ALRM}=\&timeout;

eval {
	alarm ($timeout);
	$packet=snoop($cmd);
	alarm(0);
};

if ($@ =~ "TIMEOUT") {
	print "No CDP packet - sorry\n";
	exit 1;
};
 
#
# Decode the acquired packet and print the results.
decodePacket($packet);

# The End.
