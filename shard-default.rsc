# Date: Januari 04, 2020
# Version: 0.1
# Tested: hEX Routerboard RouterOS 6.46
# HW Version: RB750Gr3
# Switching chip: 1x MT7621 
# (https://wiki.mikrotik.com/wiki/Manual:Switch_Chip_Features#Introduction)
#
# Script pushing a default configuration onto the system.
#------------------------------------------------------------------------------------

:log info "Shard DEFAULT"

# Physical interface assignment
# WARN; You have to change the configuration itself because it's hard to properly
# encode the desired state into variables. See "/interface ethernet switch vlan" below.
#
#   ether 1 = WAN Uplink (Access port)
#
#   ether 2 = DMZ/Users Zone (Trunk port)
#   ether 3 = Guests/Wifi zone (Trunk port)
#   ether 4 = Users zone (Access port)
#   ether 5 = Guests zone (Access port)

# VLAN assignment
#
# 1 is the default VLAN ID (0 doesn't exist), so we make it least secure network.
# VLAN IDs that are higher up have more access between networks.
# The VLAN IDs will match the last 8 bits of the netmask (IPv4) to make reading configuration easier.
#
# I chose to make a seperate level 2 network for WIFI because the frequency spectrum is shared and
# requires a lot of management frames to be broadcasted. These frames serve no purpose within the wired
# network.

#--------------- GLOBALS ------------------

:global "DOMAIN"

#--------------- LOCALS ------------------

# Domain for all our systems on the USERS network
:local "USER_DOMAIN" ("local" . $"DOMAIN")
# Example of a domain for all machines connected to ACTIVE DIRECTORY
# :local "AD_DOMAIN" ("AD. $"DOMAIN")

:local "WAN_IF_LIST" "WAN"
:local "LAN_IF_LIST" "LAN"
:local "PHY_SWITCH_1_IF_LIST" "PHYSICAL_BRIDGED"

:local "VLAN_USERS" "91"
:local "VLAN_WIFI" "90"
:local "VLAN_DMZ" "10"
:local "VLAN_GUESTS" "1"

#------------------------------------------------------------------------------------

:local "VLAN_ID_USERS" [:tonum $"VLAN_USERS"]
:local "VLAN_ID_WIFI" [:tonum $"VLAN_WIFI"]
:local "VLAN_ID_DMZ" [:tonum $"VLAN_DMZ"]
:local "VLAN_ID_GUESTS" [:tonum $"VLAN_GUESTS"]

/interface ethernet {
    # wait for interfaces
    :local count 0
    :while ([/interface ethernet find] = "") do={
        :if ($count = 30) do={
            :log warning "DefConf: Unable to find ethernet interfaces"
            /quit
        }
        :delay 1s
        :set count ($count +1)
    }
}

/interface list {
    # NOTE; Interface lists simplify a lot of other configuration rules, including
    # them being able to use as bridge ports.

    add name="$"WAN_IF_LIST"" comment="defconf"
    add name="$"LAN_IF_LIST"" comment="defconf"
    add name="$"PHY_SWITCH_1_IF_LIST"" comment="defconf"
}

/interface list member {
    add list="$"WAN_IF_LIST"" interface=ether1 comment="defconf"
    add list="$"PHY_SWITCH_1_IF_LIST"" interface=ether2 comment="defconf"
    add list="$"PHY_SWITCH_1_IF_LIST"" interface=ether3 comment="defconf"
    add list="$"PHY_SWITCH_1_IF_LIST"" interface=ether4 comment="defconf"
    add list="$"PHY_SWITCH_1_IF_LIST"" interface=ether5 comment="defconf"
}

/interface bridge {
    # WARN; ALWAYS start out with bridging all your physical interfaces on the same
    # switching chip!
    # 
    # Multiple bridges on the same switching chip don't support hardware offloading,
    # port isolation is not really a thing networking devices -> use VLAN
    # 
    # NOTE; Hardware offloading doesn't work when a spanning tree protocol is activated
    # on RB750Gr3! Make proper changes before disabling this feature.
    #
    # NOTE; admin-mac is used to make the MAC address of the bridge (master) interface
    # stable.

    add name="bridge1" disabled=no auto-mac=yes protocol-mode=rstp comment="defconf"

    :local bMACIsSet 0
    :foreach i in=[/interface list member find where list="$"PHY_SWITCH_1_IF_LIST""] do={
        :if ($bMACIsSet = 0) do={
            :local tmpPortName [/interface list member get $k interface]
            :foreach k in=[/interface find where name="$tmpPortName" && type="ether" && !(slave=yes || name~"bridge")] do={
                set "bridge1" auto-mac=no admin-mac=[/interface ethernet get "$tmpPortName" mac-address]
                :set bMACIsSet 1
            }
        }
    }
}

/interface ethernet switch vlan {
    add ports="ether2,ether4" vlan-id="$"VLAN_USERS"" switch="switch1" independent-learning=yes comment="defconf"
    add ports="ether3"        vlan-id="$"VLAN_WIFI"" switch="switch1" independent-learning=yes comment="defconf"
    add ports="ether2"        vlan-id="$"VLAN_DMZ"" switch="switch1" independent-learning=yes comment="defconf"
    add ports="ether3,ether5" vlan-id="$"VLAN_GUESTS"" switch="switch1" independent-learning=yes comment="defconf"
}

/interface vlan {
    add interface="bridge1" vlan-id="$"VLAN_USERS"" name="USERS" comment="defconf"
    add interface="bridge1" vlan-id="$"VLAN_WIFI"" name="WIFI" comment="defconf"
    add interface="bridge1" vlan-id="$"VLAN_DMZ"" name="DMZ" comment="defconf"
    add interface="bridge1" vlan-id="$"VLAN_GUESTS"" name="GUESTS" comment="defconf"
}

/interface list member {
    add list="$"LAN_IF_LIST"" interface="USERS" comment="defconf"
    add list="$"LAN_IF_LIST"" interface="WIFI" comment="defconf"
}

do {
    /ip address {
        # NOTE; All IP networks have a 24 bitmask length!
        
        add address=([:toip ("10.0." . $VLAN_ID_USERS . ".1")] . "/24") interface="USERS" comment="defconf"
        add address=([:toip ("10.0." . $VLAN_ID_WIFI . ".1")] . "/24") interface="WIFI" comment="defconf"
        add address=([:toip ("10.0." . $VLAN_ID_DMZ . ".1")] . "/24") interface="DMZ" comment="defconf"
        add address=([:toip ("10.0." . $VLAN_ID_GUESTS . ".1")] . "/24") interface="GUESTS" comment="defconf"
    }
} on-error={
    :log error "Couldn't generate IP-NETWORK addresses"
    /quit
}

# WARN; Entries do not contain comments!
/interface ethernet switch port {
    # NOTE; Changing vlan-mode to 'checked' or 'secure' drops all untagged traffic!
    set ether1 vlan-mode=fallback vlan-header=always-strip
    set ether2 vlan-mode=fallback vlan-header=always-strip default-vlan-id="$"VLAN_ID_USERS""
    set ether3 vlan-mode=fallback vlan-header=always-strip default-vlan-id="$"VLAN_ID_USERS""
    set ether4 vlan-mode=fallback vlan-header=always-strip default-vlan-id="$"VLAN_ID_USERS""
    set ether5 vlan-mode=fallback vlan-header=always-strip default-vlan-id="$"VLAN_ID_GUESTS""
    # TODO; Set to secure!
    set switch1-cpu vlan-mode=fallback vlan-header=add-if-missing
}

do {
    /ip pool {
        # NOTE; All IP networks have a 24 bitmask length!
        :local "IP_RANGE_USERS_START" [:toip ("10.0.". "$"VLAN_ID_USERS"" . ".10")]
        :local "IP_RANGE_USERS_END" [:toip ("10.0.". "$"VLAN_ID_USERS"" . ".254")]
        add name="POOL_USERS" ranges=($"IP_RANGE_USERS_START" ."-". $"IP_RANGE_USERS_END") comment="defconf"

        :local "IP_RANGE_WIFI_START" [:toip ("10.0.". $"VLAN_ID_WIFI" . ".10")]
        :local "IP_RANGE_WIFI_END" [:toip ("10.0.". $"VLAN_ID_WIFI" . ".254")]
        add name="POOL_WIFI" ranges=($"IP_RANGE_WIFI_START" ."-". $"IP_RANGE_WIFI_END") comment="defconf"

        :local "IP_RANGE_DMZ_START" [:toip ("10.0.". $"VLAN_ID_DMZ" . ".10")]
        :local "IP_RANGE_DMZ_END" [:toip ("10.0.". $"VLAN_ID_DMZ" . ".254")]
        add name="POOL_DMZ" ranges=($"IP_RANGE_DMZ_START" ."-". $"IP_RANGE_DMZ_END") comment="defconf"

        :local "IP_RANGE_GUESTS_START" [:toip ("10.0.". $"VLAN_ID_GUESTS" . ".10")]
        :local "IP_RANGE_GUESTS_END" [:toip ("10.0.". $"VLAN_ID_GUESTS" . ".254")]
        add name="POOL_GUESTS" ranges=($"IP_RANGE_GUESTS_START" ."-". $"IP_RANGE_GUESTS_END") comment="defconf"
    }
} on-error={
    :log error "Couldn't generate IP-POOL addresses"
    /quit
}

# WARN; Entries do not contain comments!
/ip dhcp-server {
    add address-pool="POOL_USERS" interface="USERS" name="DHCP_USERS" lease-time=10m
    add address-pool="POOL_WIFI" interface="WIFI" name="DHCP_WIFI" lease-time=10m 
    add address-pool="POOL_DMZ" interface="DMZ" name="DHCP_DMZ" lease-time=10m 
    add address-pool="POOL_GUESTS" interface="GUESTS" name="DHCP_GUESTS" lease-time=10m
}

/ip dhcp-server network {
    add address=([:toip ("10.0.". $"VLAN_ID_USERS" . ".0")] . "/24") gateway=[:toip ("10.0.". $"VLAN_ID_USERS" . ".1")] comment="defconf"
    add address=([:toip ("10.0.". $"VLAN_ID_WIFI" . ".0")] . "/24") gateway=[:toip ("10.0.". $"VLAN_ID_WIFI" . ".1")] comment="defconf"
    add address=([:toip ("10.0.". $"VLAN_ID_DMZ" . ".0")] . "/24") gateway=[:toip ("10.0.". $"VLAN_ID_DMZ" . ".1")] comment="defconf"
    add address=([:toip ("10.0.". $"VLAN_ID_GUESTS" . ".0")] . "/24") gateway=[:toip ("10.0.". $"VLAN_ID_GUESTS" . ".1")] comment="defconf"
}
    
/ip dns {
    set allow-remote-requests=yes
}

/ip dns static {
    add name=("router." . $"USER_DOMAIN") address=[:toip ("10.0.". $"VLAN_ID_USERS" . ".1")] comment="defconf"
}
   
/ip firewall nat {
    add chain=srcnat out-interface-list="$"WAN_IF_LIST"" ipsec-policy=out,none action=masquerade comment="defconf: masquerade"
}

/ip firewall filter {
    add chain=input action=accept connection-state=established,related,untracked comment="defconf: accept established,related,untracked"
    add chain=input action=drop connection-state=invalid comment="defconf: drop invalid"
    add chain=input action=accept protocol=icmp comment="defconf: accept ICMP"
    add chain=input action=accept dst-address=127.0.0.1 comment="defconf: accept to local loopback (for CAPsMAN)"
    add chain=input action=drop in-interface-list=("!". "$"LAN_IF_LIST"") comment="defconf: drop all not coming from LAN"
    add chain=forward action=accept ipsec-policy=in,ipsec comment="defconf: accept in ipsec policy"
    add chain=forward action=accept ipsec-policy=out,ipsec comment="defconf: accept out ipsec policy"
    add chain=forward action=fasttrack-connection connection-state=established,related comment="defconf: fasttrack"
    add chain=forward action=accept connection-state=established,related,untracked comment="defconf: accept established,related, untracked"
    add chain=forward action=drop connection-state=invalid comment="defconf: drop invalid"
    add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list="$"WAN_IF_LIST"" comment="defconf: drop all from WAN not DSTNATed"
}

/ipv6 firewall address-list {
    add list=bad_ipv6 address=::/128 comment="defconf: unspecified address"
    add list=bad_ipv6 address=::1 comment="defconf: lo"
    add list=bad_ipv6 address=fec0::/10 comment="defconf: site-local"
    add list=bad_ipv6 address=::ffff:0:0/96 comment="defconf: ipv4-mapped"
    add list=bad_ipv6 address=::/96 comment="defconf: ipv4 compat"
    add list=bad_ipv6 address=100::/64 comment="defconf: discard only "
    add list=bad_ipv6 address=2001:db8::/32 comment="defconf: documentation"
    add list=bad_ipv6 address=2001:10::/28 comment="defconf: ORCHID"
    add list=bad_ipv6 address=3ffe::/16 comment="defconf: 6bone"
    add list=bad_ipv6 address=::224.0.0.0/100 comment="defconf: other"
    add list=bad_ipv6 address=::127.0.0.0/104 comment="defconf: other"
    add list=bad_ipv6 address=::/104 comment="defconf: other"
    add list=bad_ipv6 address=::255.0.0.0/104 comment="defconf: other"
}

/ipv6 firewall filter {
    add chain=input action=accept connection-state=established,related,untracked comment="defconf: accept established,related,untracked"
    add chain=input action=drop connection-state=invalid comment="defconf: drop invalid"
    add chain=input action=accept protocol=icmpv6 comment="defconf: accept ICMPv6"
    add chain=input action=accept protocol=udp port=33434-33534 comment="defconf: accept UDP traceroute"
    add chain=input action=accept protocol=udp dst-port=546 src-address=fe80::/10 comment="defconf: accept DHCPv6-Client prefix delegation."
    add chain=input action=accept protocol=udp dst-port=500,4500 comment="defconf: accept IKE"
    add chain=input action=accept protocol=ipsec-ah comment="defconf: accept ipsec AH"
    add chain=input action=accept protocol=ipsec-esp comment="defconf: accept ipsec ESP"
    add chain=input action=accept ipsec-policy=in,ipsec comment="defconf: accept all that matches ipsec policy"
    add chain=input action=drop in-interface-list=("!" . "$"LAN_IF_LIST"") comment="defconf: drop everything else not coming from LAN"
    add chain=forward action=accept connection-state=established,related,untracked comment="defconf: accept established,related,untracked"
    add chain=forward action=drop connection-state=invalid comment="defconf: drop invalid"
    add chain=forward action=drop src-address-list=bad_ipv6 comment="defconf: drop packets with bad src ipv6"
    add chain=forward action=drop dst-address-list=bad_ipv6 comment="defconf: drop packets with bad dst ipv6"
    add chain=forward action=drop protocol=icmpv6 hop-limit=equal:1 comment="defconf: rfc4890 drop hop-limit=1"
    add chain=forward action=accept protocol=icmpv6 comment="defconf: accept ICMPv6"
    add chain=forward action=accept protocol=139 comment="defconf: accept HIP"
    add chain=forward action=accept protocol=udp dst-port=500,4500 comment="defconf: accept IKE"
    add chain=forward action=accept protocol=ipsec-ah comment="defconf: accept ipsec AH"
    add chain=forward action=accept protocol=ipsec-esp comment="defconf: accept ipsec ESP"
    add chain=forward action=accept ipsec-policy=in,ipsec comment="defconf: accept all that matches ipsec policy"
    add chain=forward action=drop in-interface-list=("!" . "$"LAN_IF_LIST"") comment="defconf: drop everything else not coming from LAN"
}

/ip neighbor discovery-settings {
    set discover-interface-list="$"LAN_IF_LIST""
}

/tool mac-server {
    set allowed-interface-list="$"LAN_IF_LIST""
}

/tool mac-server mac-winbox {
    set allowed-interface-list="$"LAN_IF_LIST""
}