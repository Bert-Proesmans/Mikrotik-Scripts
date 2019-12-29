# Date: December 16, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for setting up switch configuration (OSI Level 2 and below).
# This contains VLANs, VLAN bridge filtering and more.
# 
# The script assigns the following VLANs
#   ether2: disabled
#   ether3: TRUNK (GUESTS,MANAGEMENT)
#   ether4: GUESTS
#   ether5: MANAGEMENT
#
# The CPU will be accessible through both MANAGEMENT and GUESTS. On a professional configuration
# you would normally dissalow CPU access through the GUESTS VLAN. 
# GUESTS has CPU access because of the Guest DHCP server and routing.
#
# WARN(29/12/2019): Does NOT work on RB750Gr3 because of the lack of VLAN/RULE table!
# see https://wiki.mikrotik.com/wiki/Manual:Switch_Chip_Features#Introduction
#------------------------------------------------------------------------------------

:log info "Shard SWITCHING"

#--------------- GLOBALS ------------------

:global "VLAN_ID_MANAGEMENT"
:global "VLAN_ID_GUESTS"

:if (\
    [:typeof $"VLAN_ID_MANAGEMENT"] = "nothing" or \
    [:typeof $"VLAN_ID_GUESTS"] = "nothing" \
    ) do={
      :error "Not all known globals are set, script will exit"
}

#--------------- LOCALS ------------------

:local idVLANManagement [:tonum $"VLAN_ID_MANAGEMENT"]
:local idVLANGuests [:tonum $"VLAN_ID_GUESTS"]

# Name of the interface addressable through the Management VLAN
:local managementVLANIfaceName "Management"
:local guestVLANIfaceName "Guests"
#------------------------------------------------------------------------------------

# Creating a (virtual) interface for VLANs allows an IP to be assigned.
/interface vlan

# No error handling because it's possible that the combo already exists
:do { 
    add name="$managementVLANIfaceName" disabled=no \
    interface=bridge1 vlan-id=$idVLANManagement \
    comment="customconf"
} on-error={}

:do { 
    add name="$guestVLANIfaceName" disabled=no \
    interface=bridge1 vlan-id=$idVLANGuests \
    comment="customconf"
} on-error={}

# Assign addresses to VLAN interfaces.
/ip address 

# No error handling because it's possible that the combo already exists
:do { 
    add address=([:toip ("192.168." . $idVLANManagement . ".1")] . "/24") disabled=no \
    interface="$managementVLANIfaceName" \
    comment="customconf"    
} on-error={}

:do { 
    add address=([:toip ("192.168." . $idVLANGuests . ".1")] . "/24") disabled=no \
    interface="$guestVLANIfaceName" \
    comment="customconf"    
} on-error={}

# Hookup VLANs to switch ports.
/interface ethernet switch vlan

:if ([:len [find vlan-id=$idVLANManagement]] = 0) do={
    add ports=ether3 switch=switch1 vlan-id=$idVLANManagement disabled=yes \
    comment="customconf"
}

:if ([:len [find vlan-id=$idVLANGuests]] = 0) do={
    add ports=ether3 switch=switch1 vlan-id=$idVLANGuests disabled=yes \
    comment="customconf"
}

set [find vlan-id=$idVLANManagement] \
    disabled=no switch=switch1 ports=ether3,ether5,switch-cpu \
    independent-learning=yes \
    comment="customconf"

set [find vlan-id=$idVLANGuests] \
    disabled=no switch=switch1 ports=ether3,ether4,switch-cpu \
    independent-learning=yes \
    comment="customconf"

# Define VLAN port configuration within bridge.
/interface ethernet switch port

set ether3 vlan-mode=secure vlan-header=add-if-missing
set ether4 vlan-mode=secure vlan-header=add-if-missing default-vlan-id=$idVLANGuests
set ether5 vlan-mode=secure vlan-header=always-strip default-vlan-id=$idVLANManagement
set switch1-cpu vlan-mode=secure vlan-header=leave-as-is