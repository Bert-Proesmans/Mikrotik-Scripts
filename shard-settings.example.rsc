# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script containing global variable values for other scripts (aka shards).
#------------------------------------------------------------------------------------

:global "LAST_UPDATE"

:set "LAST_UPDATE" [/system clock get date]

#--------------- 

:global "ADMIN_PASS"
:global "USER_1_NAME"
:global "USER_1_PASS"

:set "ADMIN_PASS" ""
:set "USER_1_NAME" ""
:set "USER_1_PASS" ""

#--------------- 

# PPOE configuration for WAN uplink
:global "PPOE_1_USR"
:global "PPOE_1_PASS"
# NOTE; ether1 is assumed to be the internet uplink switch port, but this
# has been made configurable.
:global "PPOE_1_PHY_INTERFACE"

:set "PPOE_1_USR" ""
:set "PPOE_1_PASS" ""
:set "PPOE_1_PHY_INTERFACE" "ether1"

#---------------

:global "VLAN_ID_MANAGEMENT"
:global "VLAN_ID_GUESTS"

# NOTE; A higher ID requires more hoops to jump before getting access.
# NOTE; Guest VLAN ID "1" is chosen because the default is always "1", "0" is not an option.
# NOTE; VLAN ID numbers are chosen for clarity and to prevent fat fingering the wrong ID.
:set "VLAN_ID_MANAGEMENT" "99"
:set "VLAN_ID_GUESTS" "1"

#---------------

:global "DDNS_MATIC_USR"
:global "DDNS_MATIC_PASS"

:set "DDNS_MATIC_USR" ""
:set "DDNS_MATIC_PASS" ""

#--------------- 

:global "TIME_ZONE"
:global "DEVICE_NAME"
:global "DEVICE_NOTE"

:set "TIME_ZONE" "Europe/Brussels"
:set "DEVICE_NAME" ""
:set "DEVICE_NOTE" ""

#--------------- 

# [/interface list] entry that contains all interfaces having an uplink to the internet.
:global "WAN_IF_LIST"
:global "LAN_IF_LIST"

:set "WAN_IF_LIST" "WAN"
:set "LAN_IF_LIST" "LAN"