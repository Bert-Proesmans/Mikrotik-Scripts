# Date: October 20, 2019
# Version: 2.0
# Tested: hEX Routerboard RouterOS 6.43.4
# DNSoMatic automatic DNS updates
#
# TODO; Script needs overhaul!
#
# Mikrotik script to implement QoS on internet connections.
# The script makes use of Address Lists, Firewall rules (Mangle) for connection tagging, and Queue Trees.
# The script will remove applied rules from previous runs before applying.
#
# All data rates are expressed in bits/second.
# All accumulated data is expressed in bytes.
# You can use k,M,G to shorthand kilo (1000), mega(1000000) and giga(1000000000).
#
# Example usage:
# 1. Change the arguments indicated by '##CHANGEME';
# 2. Upload the script to RouterOS hardware through sftp;
# 3. The script is automatically executed on connection close;
#   3.1 Check the logs for possible errors
#       WARN; Most of the time this approach doesn't work because of unknown reasons..
# 4. You can manually execute the script by running the '/import filename=XX' command inside the terminal.
# 5. Update your Firewall default accept rules to not immediately FastTrack the connection. Manipulation rules 
#    are not applied on FastTracked connections and removing the flag is not possible.
#   I have 2 accept rules before FastTrack-ing:
#       * Accept when Connection-bytes: 0-2M    (Little traffic)
#       * Accept when Connection-rate: 0-150k   (Slow traffic)
# 
# NOTE(18/06/2019); When using '/import' command, make sure to use the FULL PATH. Check '/file print' for
# exact information about files on your Routerboard system. Tab completion works as well.
#
# WARN(23/06/2019): UPDATE YOUR FILTER RULES to keep 'normal' accepting data while under the TRAFFIC_BIG threshold (eg 2M).
# To achieve this your can duplicate the rule with comment `defconf: accept established,related, untracked` with `Connection Bytes`
# set to 0-2M. 
# The FastTrack rule MUST come after the mentioned one.
# The default non-FastTrack rule MUST come after the FastTrack rule.
#
# NOTE(04/10/2019): Correctly filtering VOIP traffic is réééally tough!
#

# This is the interface to run the QOS on. This is the edge interface before traffic leaves your MikroTik towards the internet.
# It can be a physical interface, or a virtual interface like PPOE.
## CHANGEME
:local QOSINTERFACE "Scarlet PPoE"
# The interface that bridges the ports of your local network.
## CHANGEME
:local LANBRIDGE "bridge LAN"

# Adjust speeds to match 90-98% of the download and upload rate for the outbound connection.
## CHANGEME
:local PCQDOWNLOAD "40M"
:local PCQUPLOAD   "5M"

## This is the name of this script. Use it to distinguish it from other QOS scripts running.
## This is used as identifier within comments, can be changed if required.
:local TREE "SPPP"

## Priority levels

# A = realtime priority
# This includes CS5 and up
# LEVEL_A_UP - LEVEL_A_DOWN

# B = normal priority
# This includes CS1 and up
# LEVEL_B_UP - LEVEL_B_DOWN

# C = bulk priority
# This includes best effort and high bandwidth connections
# LEVEL_C_UP - LEVEL_C_DOWN

###############################################################################
# Collect IP ranges for important services ##
#
###############################################################################

/ipv6 firewall address-list

# Reset
:foreach i in=[find list="games"] do={
    remove $i
}

add address=2801:1b:6000::/48 comment="LoL (Europe)" list=games
add address=2a04:82c0::/29 comment="LoL (Europe)" list=games
add address=2804:3ec0::/32 comment="LoL (Europe)" list=games

# NOTE; IPV4
/ip firewall address-list

# Reset
:foreach i in=[find list="games"] do={
    remove $i
}

# Riot League of Legends

# Ports
# 5000 - 5500 UDP
# 8393 - 8400 TCP
# 80    TCP
# 443   TCP

# AS6507
add address=8.23.24.0/23 comment="League of Legends West" list=games
add address=43.229.64.0/22 comment="League of Legends West" list=games
add address=43.229.64.0/24 comment="League of Legends West" list=games
add address=43.229.65.0/24 comment="League of Legends West" list=games
add address=43.229.66.0/24 comment="League of Legends West" list=games
add address=43.229.67.0/24 comment="League of Legends West" list=games
add address=45.7.36.0/24 comment="League of Legends West" list=games
add address=45.7.39.0/24 comment="League of Legends West" list=games
add address=45.250.208.0/22 comment="League of Legends West" list=games
add address=66.151.33.0/24 comment="League of Legends West" list=games
add address=103.219.128.0/22 comment="League of Legends West" list=games
add address=103.240.224.0/24 comment="League of Legends West" list=games
add address=103.240.225.0/24 comment="League of Legends West" list=games
add address=103.240.226.0/23 comment="League of Legends West" list=games
add address=104.160.128.0/19 comment="League of Legends West" list=games
add address=104.160.128.0/20 comment="League of Legends West" list=games
add address=104.160.134.0/24 comment="League of Legends West" list=games
add address=104.160.135.0/24 comment="League of Legends West" list=games
add address=104.160.136.0/24 comment="League of Legends West" list=games
add address=104.160.139.0/24 comment="League of Legends West" list=games
add address=104.160.141.0/24 comment="League of Legends West" list=games
add address=104.160.142.0/24 comment="League of Legends West" list=games
add address=104.160.143.0/24 comment="League of Legends West" list=games
add address=104.160.144.0/24 comment="League of Legends West" list=games
add address=104.160.145.0/24 comment="League of Legends West" list=games
add address=104.160.146.0/24 comment="League of Legends West" list=games
add address=104.160.147.0/24 comment="League of Legends West" list=games
add address=104.160.148.0/24 comment="League of Legends West" list=games
add address=104.160.149.0/24 comment="League of Legends West" list=games
add address=104.160.152.0/21 comment="League of Legends West" list=games
add address=104.160.153.0/24 comment="League of Legends West" list=games
add address=104.160.154.0/24 comment="League of Legends West" list=games
add address=104.160.155.0/24 comment="League of Legends West" list=games
add address=104.160.156.0/24 comment="League of Legends West" list=games
add address=110.45.191.0/24 comment="League of Legends West" list=games
add address=117.52.75.0/24 comment="League of Legends West" list=games
add address=117.52.76.0/22 comment="League of Legends West" list=games
add address=117.52.101.0/24 comment="League of Legends West" list=games
add address=138.0.12.0/22 comment="League of Legends West" list=games
add address=138.0.12.0/24 comment="League of Legends West" list=games
add address=138.0.13.0/24 comment="League of Legends West" list=games
add address=138.0.14.0/24 comment="League of Legends West" list=games
add address=138.0.15.0/24 comment="League of Legends West" list=games
add address=162.249.72.0/22 comment="League of Legends West" list=games
add address=162.249.76.0/22 comment="League of Legends West" list=games
add address=162.249.79.0/24 comment="League of Legends West" list=games
add address=182.162.120.0/21 comment="League of Legends West" list=games
add address=185.40.64.0/22 comment="League of Legends West" list=games
add address=192.64.168.0/24 comment="League of Legends West" list=games
add address=192.64.169.0/24 comment="League of Legends West" list=games
add address=192.64.170.0/24 comment="League of Legends West" list=games
add address=192.64.171.0/24 comment="League of Legends West" list=games
add address=192.64.172.0/24 comment="League of Legends West" list=games
add address=192.64.173.0/24 comment="League of Legends West" list=games
add address=192.64.174.0/24 comment="League of Legends West" list=games
add address=192.64.175.0/24 comment="League of Legends West" list=games

# Steam ports

# Ports
# 27015-27030 UDP+TCP
# 80    TCP
# 443   TCP

# AS32590
add address=146.66.152.0/23 comment="Steam Europe" list=games
add address=146.66.154.0/24 comment="Steam Europe" list=games
add address=146.66.155.0/24 comment="Steam Europe" list=games
add address=146.66.156.0/23 comment="Steam Europe" list=games
add address=146.66.158.0/23 comment="Steam Europe" list=games
add address=185.25.180.0/23 comment="Steam Europe" list=games
add address=185.25.182.0/24 comment="Steam Europe" list=games
add address=185.25.183.0/24 comment="Steam Europe" list=games
add address=155.133.224.0/23 comment="Steam Europe" list=games
add address=155.133.227.0/24 comment="Steam Europe" list=games
add address=155.133.228.0/23 comment="Steam Europe" list=games
add address=155.133.230.0/23 comment="Steam Europe" list=games
add address=155.133.232.0/24 comment="Steam Europe" list=games
add address=155.133.233.0/24 comment="Steam Europe" list=games
add address=155.133.234.0/24 comment="Steam Europe" list=games
add address=155.133.235.0/24 comment="Steam Europe" list=games
add address=155.133.236.0/23 comment="Steam Europe" list=games
add address=155.133.238.0/24 comment="Steam Europe" list=games
add address=155.133.239.0/24 comment="Steam Europe" list=games
add address=155.133.240.0/23 comment="Steam Europe" list=games
add address=155.133.242.0/23 comment="Steam Europe" list=games
add address=155.133.244.0/24 comment="Steam Europe" list=games
add address=155.133.245.0/24 comment="Steam Europe" list=games
add address=155.133.246.0/23 comment="Steam Europe" list=games
add address=155.133.248.0/24 comment="Steam Europe" list=games
add address=155.133.249.0/24 comment="Steam Europe" list=games
add address=155.133.250.0/24 comment="Steam Europe" list=games
add address=155.133.252.0/24 comment="Steam Europe" list=games
add address=155.133.253.0/24 comment="Steam Europe" list=games
add address=155.133.254.0/24 comment="Steam Europe" list=games
add address=155.133.255.0/24 comment="Steam Europe" list=games

# Blizzard (Overwatch)

# Ports
# ANY? UDP+TCP
# 80    TCP
# 443   TCP

# AS57976
add address=5.42.160.0/20 comment="Blizzard Europe" list=games
add address=5.42.176.0/20 comment="Blizzard Europe" list=games
add address=37.244.15.0/24 comment="Blizzard Europe" list=games
add address=37.244.16.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.17.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.18.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.19.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.20.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.21.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.22.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.23.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.24.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.25.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.26.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.27.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.28.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.29.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.30.0/23 comment="Blizzard Europe" list=games 	
add address=37.244.32.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.33.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.34.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.35.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.36.0/23 comment="Blizzard Europe" list=games 	
add address=37.244.38.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.40.0/22 comment="Blizzard Europe" list=games 	
add address=37.244.44.0/22 comment="Blizzard Europe" list=games 	
add address=37.244.48.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.49.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.50.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.52.0/23 comment="Blizzard Europe" list=games 	
add address=37.244.54.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.55.0/24 comment="Blizzard Europe" list=games 	
add address=37.244.56.0/23 comment="Blizzard Europe" list=games 	
add address=37.244.58.0/23 comment="Blizzard Europe" list=games 	
add address=37.244.60.0/22 comment="Blizzard Europe" list=games
add address=185.60.112.0/23 comment="Blizzard Europe" list=games
add address=185.60.114.0/23 comment="Blizzard Europe" list=games
add address=137.221.64.0/19 comment="Blizzard Europe" list=games
add address=137.221.64.0/24 comment="Blizzard Europe" list=games
add address=137.221.68.0/24 comment="Blizzard Europe" list=games
add address=137.221.69.0/24 comment="Blizzard Europe" list=games
add address=137.221.70.0/24 comment="Blizzard Europe" list=games
add address=137.221.71.0/24 comment="Blizzard Europe" list=games
add address=137.221.72.0/24 comment="Blizzard Europe" list=games
add address=137.221.73.0/24 comment="Blizzard Europe" list=games
add address=137.221.74.0/24 comment="Blizzard Europe" list=games
add address=137.221.75.0/24 comment="Blizzard Europe" list=games
add address=137.221.76.0/24 comment="Blizzard Europe" list=games 	
add address=137.221.77.0/24 comment="Blizzard Europe" list=games
add address=137.221.78.0/24 comment="Blizzard Europe" list=games
add address=137.221.79.0/24 comment="Blizzard Europe" list=games
add address=137.221.80.0/24 comment="Blizzard Europe" list=games
add address=137.221.81.0/24 comment="Blizzard Europe" list=games
add address=137.221.82.0/24 comment="Blizzard Europe" list=games
add address=137.221.83.0/24 comment="Blizzard Europe" list=games
add address=137.221.84.0/24 comment="Blizzard Europe" list=games
add address=137.221.85.0/24 comment="Blizzard Europe" list=games
add address=137.221.86.0/24 comment="Blizzard Europe" list=games
add address=137.221.96.0/22 comment="Blizzard Europe" list=games 	
add address=137.221.100.0/22 comment="Blizzard Europe" list=games 	
add address=137.221.104.0/22 comment="Blizzard Europe" list=games

###############################################################################
# Mangle Rules to tag traffic
#
# DSCP conversion table
# NOTE: Not all DS field values are used!
#   -> Try to fill the list with actually used tags. Also because they override any other connection
#      marking!
# 
# | DSCP Name 	    | DS Field Value (Dec) 	| IP Precedence (Description)
# -----------------------------------------------------------------------
# | CS0 	        | 0 	                | 0: Best Effort
# | CS1, AF11-13 	| 8,10,12,14 	        | 1: Priority   (Class 1)
# | CS2, AF21-23 	| 16,18,20,22 	        | 2: Immediate  (Class 2)
# | CS3, AF31-33 	| 24,26,28,30 	        | 3: Flash - mainly used for voice signaling(Class 3)
# | CS4, AF41-43 	| 32,34,36,38 	        | 4: Flash Override                         (Class 4)
# | CS5, EF 	    | 40,46 	            | 5: Critical - mainly used for voice RTP
# | CS6 	        | 48 	                | 6: Internetwork Control
# | CS7 	        | 56 	                | 7: Network Control 
###############################################################################

# NOTE; Connection-rate and Connection-bytes are reset. Care must be taken to not assign higher priority when a lower priority has been assigned!
# NOTE; The rules are mostly applied in pre- and postrouting, so connections to/from the router itself are subject as well!
/ip firewall mangle

# Reset
:foreach i in=[find where comment~("autoconf:" . $TREE)] do={
    remove $i
}

add action=log chain=notes comment=("autoconf:" . $TREE . " Start of QoS tree.")

# WARN; Connection-rate is a value updated per second. Make sure to prevent falling back from *-big to * connections doesn't happen! 
# Seperate rules need to be created to transform the general marker back into the specific mark!
add action=mark-connection chain=prerouting connection-mark="OTHER_BIG" new-connection-mark="BIG_MARKER" comment=("autoconf:" . $TREE . " BIG PERSISTENT")
add action=mark-connection chain=prerouting connection-mark="HTTP_BIG"  new-connection-mark="BIG_MARKER" comment=("autoconf:" . $TREE . " BIG PERSISTENT")

# Mark all leftover TCP traffic.
add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="OTHER" protocol=tcp comment=("autoconf:" . $TREE . " OTHER")
# Mark all leftover UDP traffic.
add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="OTHER" protocol=udp comment=("autoconf:" . $TREE . " OTHER")

# Mark VOIP and VOIP like traffic. WARN; This is icky ground, because a lot of different traffic could be caught with these rules (like torrenting)!
## RTP (port range too broad, so it's kept as example)
# add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="VOIP" connection-rate=0-100k port=10000-20000 protocol=udp comment=("autoconf:" . $TREE . " VOIP")
## Discord
add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="VOIP"      connection-rate=0-100k port=55000-65000 protocol=udp comment=("autoconf:" . $TREE . " VOIP")
# NOTE; Validate general BIG_MARKER back into subcategories.
add action=mark-connection chain=prerouting connection-mark="BIG_MARKER"  new-connection-mark="OTHER_BIG" connection-rate=0-100k port=55000-65000 protocol=udp comment=("autoconf:" . $TREE . " VOIP")

# Mark all new HTTP(s) connections with "HTTP" if they have not previously been marked as "HTTP_BIG".
# NOTE; This HTTP mark also tries to target QUIC traffic (UDP on HTTP common ports)
add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="HTTP"     protocol=tcp port=80,81,443,444,554,8000,8080,8409 comment=("autoconf:" . $TREE . " HTTP")
add action=mark-connection chain=prerouting connection-mark="!BIG_MARKER" new-connection-mark="HTTP"     protocol=udp port=80,81,443,444,554,8000,8080,8409 comment=("autoconf:" . $TREE . " QUIC")
# NOTE; Validate general BIG_MARKER back into subcategories
add action=mark-connection chain=prerouting connection-mark="BIG_MARKER"  new-connection-mark="HTTP_BIG" protocol=tcp port=80,81,443,444,554,8000,8080,8409 comment=("autoconf:" . $TREE . " HTTP")    
add action=mark-connection chain=prerouting connection-mark="BIG_MARKER"  new-connection-mark="HTTP_BIG" protocol=udp port=80,81,443,444,554,8000,8080,8409 comment=("autoconf:" . $TREE . " QUIC")

# Catch big traffic
# ..everything non-tagged above 1MB.
add action=mark-connection chain=prerouting connection-mark="OTHER" new-connection-mark="OTHER_BIG"                        connection-bytes=1M-0 protocol=tcp comment=("autoconf:" . $TREE . " OTHER BIG")
# ..VOIP traffic that keeps a sustained rate above 200kb after 1MB (~4 seconds).
add action=mark-connection chain=prerouting connection-mark="VOIP"  new-connection-mark="OTHER_BIG" connection-rate=200k-0 connection-bytes=1M-0 protocol=udp comment=("autoconf:" . $TREE . " OTHER BIG")
# ..HTTP connections above 2MB: heavy web resources.
# NOTE; HTTP1/1.1 clients open multiple connections for a single web page, it's hard to punish heavy webpages this way!
# HTTP2/3(QUIC) attempt to multiplex requests across already open connections, so traffic shaping by connection becomes easier for us.
add action=mark-connection chain=prerouting connection-mark="HTTP"       new-connection-mark="HTTP_BIG"   connection-bytes=2M-0 protocol=tcp comment=("autoconf:" . $TREE . " HTTP BIG")
add action=mark-connection chain=prerouting connection-mark="HTTP"       new-connection-mark="HTTP_BIG"   connection-bytes=2M-0 protocol=udp comment=("autoconf:" . $TREE . " QUIC")

# Defined game servers.
# NOTE; Override connection-mark. Only when the filter conditions can be expressed to match the traffic exactly!
add action=mark-connection chain=prerouting  new-connection-mark="GAMES" dst-address-list=games comment=("autoconf:" . $TREE . " GAMES")

# DNS requests. 
# WARN; Mark in pre- and postrouting because DNS is sent out by the router (itself) too.
# NOTE; Override connection-mark.
add action=mark-connection chain=prerouting  new-connection-mark="DNS" protocol=udp port=53 comment=("autoconf:" . $TREE . " DNS")
add action=mark-connection chain=postrouting new-connection-mark="DNS" protocol=udp port=53 comment=("autoconf:" . $TREE . " DNS")

# ICMP
# NOTE; Override connection-mark.
add action=mark-connection chain=prerouting  new-connection-mark="ICMP" protocol=icmp comment=("autoconf:" . $TREE . " ICMP")
add action=mark-connection chain=postrouting new-connection-mark="ICMP" protocol=icmp comment=("autoconf:" . $TREE . " ICMP")

# WINBOX
# The connection to the router on the specified port, which should get IP control priority.
# NOTE; Override connection-mark.
add action=mark-connection chain=input new-connection-mark="ICMP" protocol=tcp port=8291 comment=("autoconf:" . $TREE . " WINBOX")

# Set priority tags inside the packets.
add action=set-priority chain=postrouting connection-mark="VOIP"   new-priority=6  comment=("autoconf:" . $TREE)
add action=change-dscp  chain=postrouting connection-mark="VOIP"   new-dscp=48     comment=("autoconf:" . $TREE)
add action=set-priority chain=postrouting connection-mark="DNS"    new-priority=6  comment=("autoconf:" . $TREE)
add action=change-dscp  chain=postrouting connection-mark="DNS"    new-dscp=48     comment=("autoconf:" . $TREE)
add action=set-priority chain=postrouting connection-mark="ICMP"   new-priority=6  comment=("autoconf:" . $TREE)
add action=change-dscp  chain=postrouting connection-mark="ICMP"   new-dscp=48     comment=("autoconf:" . $TREE)

## ACK Packets
# NOTE; ACKs are just flagged packets on a TCP connection. No connection-mark can be set/used.
add action=set-priority chain=postrouting new-priority=6 protocol=tcp tcp-flags=ack packet-size=0-123 comment=("autoconf:" . $TREE)
add action=change-dscp  chain=postrouting new-dscp=48    protocol=tcp tcp-flags=ack packet-size=0-123 comment=("autoconf:" . $TREE)

## DSCP comes from the client indicating priority. The provided information will always overrule any other configuration!
add action=set-priority chain=postrouting dscp=46 new-priority=6 comment=("autoconf:" . $TREE)
add action=set-priority chain=postrouting dscp=48 new-priority=6 comment=("autoconf:" . $TREE)

add action=mark-packet  chain=prerouting  protocol=tcp tcp-flags=ack  new-packet-mark="ACK_D"       packet-size=0-123 in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  protocol=tcp tcp-flags=ack  new-packet-mark="ACK_U"       packet-size=0-123 in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="DNS"       new-packet-mark="DNS_D"                         in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="DNS"       new-packet-mark="DNS_U"                         in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="ICMP"      new-packet-mark="ICMP_D"                        in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="ICMP"      new-packet-mark="ICMP_U"                        in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="VOIP"      new-packet-mark="VOIP_D"      packet-size=0-260 in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="VOIP"      new-packet-mark="VOIP_U"      packet-size=0-260 in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)

add action=mark-packet  chain=prerouting  connection-mark="GAMES"     new-packet-mark="GAMES_D"                       in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="GAMES"     new-packet-mark="GAMES_U"                       in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="HTTP"      new-packet-mark="HTTP_D"                        in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="HTTP"      new-packet-mark="HTTP_U"                        in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="HTTP_BIG"  new-packet-mark="HTTP_D_BIG"                    in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="HTTP_BIG"  new-packet-mark="HTTP_U_BIG"                    in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)

add action=mark-packet  chain=prerouting  connection-mark="OTHER"     new-packet-mark="OTHER_D"                       in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting  connection-mark="OTHER"     new-packet-mark="OTHER_U"                       in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)

# Give packet lowest priority if no othe rule matched. (This includes BIG_MARKER connections!)
add action=mark-packet  chain=prerouting                              new-packet-mark="OTHER_D_BIG"                   in-interface=($QOSINTERFACE)  passthrough=no comment=("autoconf:" . $TREE)
add action=mark-packet  chain=prerouting                              new-packet-mark="OTHER_U_BIG"                   in-interface=($LANBRIDGE)     passthrough=no comment=("autoconf:" . $TREE)


###############################################################################
# HTB Queue Tree is a unidirectional queue. 
# The queue works on outbound interfaces, so eth1 (public interface) is for upload 
# and eth2 (private interface) is for download.
#
# Notes:
# priority means 'drop packets' WHEN needed.
# When limit-at=0   priority starts when max-limit is reached.
# When limit-at=123 priority starts when limit-at is reached.
#
# The priority option applies to CHILDREN not parents. Parent is for setting
# overall limits. Therefore use limit-at and max-limit on the children if
# you want more granularity.
#
# max-limit must always be set or priority will not happen.
#
# Tips for TCP (not VoIP) SOHO network:
# limit-at  = Total bandwidth / max hosts 
# max-limit = Total bandwidth / min hosts 
#
###############################################################################

/queue type

# Reset all custom queue types (even types NOT created by this script!)
:foreach i in=[find] do= {
    :do {
      remove $i
    } on-error={}
}

# Red queues shape bittorrent traffic better (high amount of connections with spiked start)
add kind=red name=red-download red-avg-packet=1500 red-burst=10 red-limit=40 red-max-threshold=40
add kind=red name=red-upload   red-avg-packet=1500 red-burst=5  red-limit=20 red-max-threshold=20 red-min-threshold=5
add kind=sfq name=default-sfq  sfq-perturb=5 sfq-allot=1514

# Update default PCQ queues for per IP
set [find where name="pcq-download-default"] pcq-classifier=dst-address pcq-rate=($PCQDOWNLOAD) pcq-total-limit=25000
set [find where name="pcq-upload-default"]   pcq-classifier=src-address pcq-rate=($PCQUPLOAD)   pcq-total-limit=25000

##

/queue tree

# Reset
:foreach i in=[find where (name~("^".$TREE) || parent~("^".$TREE))] do={
    remove $i
}

add name=($TREE . "_TOTAL_UP")   parent=($QOSINTERFACE)                                        max-limit=($PCQUPLOAD)              queue=default
add name=($TREE . "_TOTAL_DOWN") parent=($LANBRIDGE)                                           max-limit=($PCQDOWNLOAD)            queue=default

add name="ACK_U"       parent=($TREE . "_TOTAL_UP")   packet-mark="ACK_U"       limit-at=1500k max-limit=($PCQUPLOAD)   priority=1 queue=default 
add name="ACK_D"       parent=($TREE . "_TOTAL_DOWN") packet-mark="ACK_D"       limit-at=4M    max-limit=($PCQDOWNLOAD) priority=1 queue=default 

add name="VOIP_U"      parent=($TREE . "_TOTAL_UP")   packet-mark="VOIP_U"      limit-at=1500k max-limit=($PCQUPLOAD)   priority=2 queue=default
add name="VOIP_D"      parent=($TREE . "_TOTAL_DOWN") packet-mark="VOIP_D"      limit-at=4M    max-limit=($PCQDOWNLOAD) priority=2 queue=default

add name="GAMES_U"     parent=($TREE . "_TOTAL_UP")   packet-mark="GAMES_U"     limit-at=1500k max-limit=($PCQUPLOAD)   priority=3 queue=default-sfq
add name="GAMES_D"     parent=($TREE . "_TOTAL_DOWN") packet-mark="GAMES_D"     limit-at=4M    max-limit=($PCQDOWNLOAD) priority=3 queue=default

add name="DNS_U"       parent=($TREE . "_TOTAL_UP")   packet-mark="DNS_U"       limit-at=1500k max-limit=($PCQUPLOAD)   priority=4 queue=default 
add name="DNS_D"       parent=($TREE . "_TOTAL_DOWN") packet-mark="DNS_D"       limit-at=4M    max-limit=($PCQDOWNLOAD) priority=4 queue=default 

add name="ICMP_U"      parent=($TREE . "_TOTAL_UP")   packet-mark="ICMP_U"      limit-at=1500k max-limit=($PCQUPLOAD)   priority=5 queue=default 
add name="ICMP_D"      parent=($TREE . "_TOTAL_DOWN") packet-mark="ICMP_D"      limit-at=4M    max-limit=($PCQDOWNLOAD) priority=5 queue=default 

add name="HTTP_U"      parent=($TREE . "_TOTAL_UP")   packet-mark="HTTP_U"      limit-at=100k  max-limit=($PCQUPLOAD)   priority=6 queue=pcq-upload-default
add name="HTTP_D"      parent=($TREE . "_TOTAL_DOWN") packet-mark="HTTP_D"      limit-at=250k  max-limit=($PCQDOWNLOAD) priority=6 queue=pcq-download-default

add name="HTTP_U_BIG"  parent=($TREE . "_TOTAL_UP")   packet-mark="HTTP_U_BIG"  limit-at=100k  max-limit=($PCQUPLOAD)   priority=7 queue=pcq-upload-default
add name="HTTP_D_BIG"  parent=($TREE . "_TOTAL_DOWN") packet-mark="HTTP_D_BIG"  limit-at=250k  max-limit=($PCQDOWNLOAD) priority=7 queue=pcq-download-default

add name="OTHER_U"     parent=($TREE . "_TOTAL_UP")   packet-mark="OTHER_U"     limit-at=100k  max-limit=($PCQUPLOAD)   priority=8 queue=red-upload
add name="OTHER_D"     parent=($TREE . "_TOTAL_DOWN") packet-mark="OTHER_D"     limit-at=250k  max-limit=($PCQDOWNLOAD) priority=8 queue=red-download

add name="OTHER_U_BIG" parent=($TREE . "_TOTAL_UP")   packet-mark="OTHER_U_BIG" limit-at=100k  max-limit=($PCQUPLOAD)   priority=8 queue=red-upload
add name="OTHER_D_BIG" parent=($TREE . "_TOTAL_DOWN") packet-mark="OTHER_D_BIG" limit-at=250k  max-limit=($PCQDOWNLOAD) priority=8 queue=red-download