# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for performing post-reset configuration.
# 
# WARN; This script builds on top of the default (stage 2) configuration, which includes
# a bridge, firewall rules etc.
#
# WARN; This script assumes all other scripts are located at the root of the flash filesystem.
#------------------------------------------------------------------------------------

:log info "INIT-SCRIPT"

:do { /import flash/shard-settings.rsc } on-error={ :error "Failed loading settings" }

:do { /import flash/shard-ppp.rsc} on-error={ :error "Failed initializing PPP" }



:do { /import flash/shard-identity.rsc } on-error={ :error "Failed setting up router identity" }

:do { /import flash/shard-users.rsc} on-error={ :error "Failed setting up users" }

#---------------

:log info "Finished, clearing all global variables and rebooting"

/system script environment
:foreach var in=[find] do={
    remove $var
}

# NOTE; The exclamation point prevents the terminal from asking verification!
/system reboot !