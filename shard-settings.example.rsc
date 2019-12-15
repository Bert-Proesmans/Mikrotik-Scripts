# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script containing global variable values for other scripts (aka shards).
#------------------------------------------------------------------------------------

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
:global "PPOE_1_PHY_INTERFACE"

:set "PPOE_1_USR" ""
:set "PPOE_1_PASS" ""
:set "PPOE_1_PHY_INTERFACE" "ether"

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