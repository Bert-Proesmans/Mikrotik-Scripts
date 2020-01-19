# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script containing global variable values for other scripts (aka shards).
#------------------------------------------------------------------------------------

:global "LAST_UPDATE" [/system clock get date]

#--------------- 

:global "ADMIN_PASS"    ""
:global "USER_1_NAME"   ""
:global "USER_1_PASS"   ""

#--------------- 

# The TLD of our site.
# All networks will be part of this domain.
:global "DOMAIN" ""

#---------------

:global "TIME_ZONE"
:global "DEVICE_NAME"
:global "DEVICE_NOTE"

:set "TIME_ZONE" "Europe/Brussels"
:set "DEVICE_NAME" ""
:set "DEVICE_NOTE" ""

#--------------- 

# PPOE configuration for WAN uplink
:global "PPOE_1_USR"    ""
:global "PPOE_1_PASS"   ""
# NOTE; ether1 is assumed to be the internet uplink switch port, but this
# has been made configurable.
:global "PPOE_1_PHY_INTERFACE"  "ether1"

#--------------- 