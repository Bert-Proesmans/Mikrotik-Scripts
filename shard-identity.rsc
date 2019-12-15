# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for managing system identity configuration.
#------------------------------------------------------------------------------------

:log info "Shard Identity"

#--------------- GLOBALS ------------------
:global "TIME_ZONE"
:global "DEVICE_NAME"
:global "DEVICE_NOTE"

:if (\
    [:typeof $"TIME_ZONE"] = "nothing" or \
    [:typeof $"DEVICE_NAME"] = "nothing" \
    ) do={
      :error "Not all known globals are set, script will exit"
}

#--------------- LOCALS ------------------

:local deviceNote $"DEVICE_NOTE"

#------------------------------------------------------------------------------------

/system clock

set time-zone-name="$"TIME_ZONE""

/system identity

set name="$"DEVICE_NAME""

/system note

set note="$deviceNote" show-at-login=yes