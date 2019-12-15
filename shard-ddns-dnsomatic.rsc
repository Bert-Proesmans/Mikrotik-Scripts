# Date: October 27, 2018
# Version: 1.1
# Tested: hEx Routerboard RouterOS 6.43.2
# DNSoMatic automatic DNS updates
#
# TODO; Script needs overhaul!
#------------------------------------------------------------------------------------

:log info "Shard DDNS-DNSOMATIC"

#--------------- GLOBALS ------------------
:global "DDNS_MATIC_USR"
:global "DDNS_MATIC_PASS"
:global "WAN_IF_LIST"
# Discovered IP address of the previous run of this script.
:global "DDNS_MATIC_PREVIOUS_IP"

:if (\
    [:typeof $"DDNS_MATIC_USR"] = "nothing" or \
    [:typeof $"DDNS_MATIC_PASS"] = "nothing" or \
    [:typeof $"WAN_IF_LIST"] = "nothing" \
    ) do={
      :error "Not all known globals are set, script will exit"
}

#--------------- LOCALS ------------------

# User account info of DNSoMatic

:local maticuser $"DDNS_MATIC_USR"
:local maticpass $"DDNS_MATIC_PASS"

# Set the hostname or label of network to be updated. 
# This is the part after the double colon (::) on the DNSoMatic services page.
# Hostnames with spaces are unsupported. Replace the value in the quotations below with your host names.
# To specify multiple hosts, separate them with commas. 
# Use "all.dnsomatic.com" for the matichost to update all items in dnsomatic with this IP.

:local matichost "all.dnsomatic.com"

# Temporary storage of the IP address we're going to use for updating.

:local targetIP

#------------------------------------------------------------------------------------

# Attempt to find the first dynamic IP address of the first active interface member of the list $WAN_IF_LIST
:foreach ifaceMember in [/interface list member find list=$"WAN_IF_LIST"] do={
    :local currentIface [/interface list member get $ifaceMember interface]
    :if ([/interface get "$currentIface" value-name=running]) do={
        :do {
            :local currentIP [/ip address get [find interface="$currentIface" disabled=no dynamic] address]
            :if ([:len $currentIP] > 0) do={
                :set $targetIP "$currentIP"
            }
        # No error action because there might be no addresses for the specified interface!
        } on-error={}
    }
}

:put $currentIP

#:if ([/interface get $inetinterface value-name=running]) do={
## Get the current IP on the interface
#    :local currentIP [/ip address get [find interface="$inetinterface" disabled=no] address];
#    
## Strip the net mask off the IP address
#    :put [:pick $currentIP 0 [:find $currentIP "/"]]
#
## Update the address list with the new WAN IP address
#    /ip firewall address-list
#    :if ([:len [find address="$currentIP" list=$wanlist]] > 0) do={
#         /ip firewall address-list set timeout=$listtimeout [find address="$currentIP" list=$wanlist]
#        :log info "DNSoMatic: WAN address-list timer reset"
#    } else={
#        /ip firewall address-list add address="$currentIP" timeout=$listtimeout list=$wanlist
#        :log info "DNSoMatic: New WAN address-list entry"
#    }
#
#    :if ($currentIP != $previousIP) do={
#        :log info "DNSoMatic: Update needed"
#        :set previousIP $currentIP
#        
## The update URL. Note the "\3F" is hex for question mark (?). Required since ? is a special character in commands.
#        :local url "https://updates.dnsomatic.com/nic/update\3Fmyip=$currentIP&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG"
#        :local matichostarray;
#        :set matichostarray [:toarray $matichost];
#        :foreach host in=$matichostarray do={
#            :log info "DNSoMatic: Sending update for $host"
#            /tool fetch url=($url . "&hostname=$host") user=$maticuser password=$maticpass mode=https dst-path=("dnsomaticupdate-" . $host . ".txt")
#            :log info "DNSoMatic: Host $host updated on DNSoMatic with IP $currentIP"
#        }
#    }  else={
#        :log info "DNSoMatic: Previous IP $previousIP and current IP equal, no update need"
#    }
#} else={
#    :log info "DNSoMatic: $inetinterface is not currently running, so therefore will not update."
#}