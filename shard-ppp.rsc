# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for setting up a new PPP interface connections.
#------------------------------------------------------------------------------------

:log info "Shard PPP"

#--------------- GLOBALS ------------------
:global "PPOE_1_USR"
:global "PPOE_1_PASS"
:global "PPOE_1_PHY_INTERFACE"

:if (\
    [:typeof $"PPOE_1_USR"] = "nothing" or \
    [:typeof $"PPOE_1_PASS"] = "nothing" or \
    [:typeof $"PPOE_1_PHY_INTERFACE"] = "nothing" \
    ) do={
      :error "Not all known globals are set, script will exit"
}

#--------------- LOCALS ------------------

:local "WAN_IF_LIST" "WAN"

# PPOE account info

:local ppoeUser "$"PPOE_1_USR""
:local ppoePass "$"PPOE_1_PASS""

# The interface name for creation and reference

:local ppoeIface "PPOE 1"

#------------------------------------------------------------------------------------

/interface pppoe-client

:if ([:len [find name="$ppoeIface"]] = 0) do={
    add name="$ppoeIface" disabled=yes \
    interface="$"PPOE_1_PHY_INTERFACE"" \
    comment="customconf"
}

set [find name="$ppoeIface"] \
    add-default-route=yes allow=pap,chap,mschap1,mschap2 \
    default-route-distance=1 dial-on-demand=no \
    keepalive-timeout=10 max-mru=auto max-mtu=auto mrru=disabled \
    profile=default service-name="" use-peer-dns=yes \
    disabled=no interface="$"PPOE_1_PHY_INTERFACE"" \
    user="$ppoeUser" password="$ppoePass"

# WARN; We assume interface list "WAN" already exists through defconf!
/interface list member

# No error handling because it's possible that the combo already exists
:do { 
    add interface="$ppoeIface" list="$"WAN_IF_LIST"" disabled=no \
    comment="customconf"    
} on-error={}