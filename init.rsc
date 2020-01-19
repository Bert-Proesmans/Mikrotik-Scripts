# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for performing post-reset configuration. (customconf)
#
# WARN(15/12/2019); This script assumes all other scripts are located at the root of the flash filesystem.
#
# NOTE(18/06/2019); When using '/import' command, make sure to use the FULL PATH. Check '/file print' for
# exact information about files on your Routerboard system. Tab completion works as well.
#------------------------------------------------------------------------------------

:log info "INIT-SCRIPT"

:do { /import flash/shard-settings.rsc } on-error={ :error "Failed loading settings" }

# NOTE; Identity and users are executed first, because errors in other scripts will exit the script early!
:do { /import flash/shard-identity.rsc } on-error={ :error "Failed setting up router identity" }
:do { /import flash/shard-users.rsc} on-error={ :error "Failed setting up users" }

# Settings derived from the Mikrotik default configuration.
# :do { /import flash/shard-default.rsc } on-error={ :error "Failed applying default settings" }

# Internet setup.
:do { /import flash/shard-ppp.rsc} on-error={ :error "Failed initializing PPP" }

# Network configuration.
# :do { /import flash/shard-QOS.rsc} on-error={ :error "Failed setting QOS configuration" }

#---------------

:log info "Finished, clearing all global variables and rebooting"

/system script environment
:foreach var in=[find] do={
    remove $var
}

/system reboot