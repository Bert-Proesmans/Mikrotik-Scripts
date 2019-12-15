# Date: December 15, 2019
# Version: 0.1
# Tested: hEx Routerboard RouterOS 6.46
#
# Script for managing system users.
#------------------------------------------------------------------------------------

:log info "Shard USERS"

#--------------- GLOBALS ------------------
:global "ADMIN_PASS"
:global "USER_1_NAME"
:global "USER_1_PASS"

:if (\
    [:typeof $"ADMIN_PASS"] = "nothing" or \
    [:typeof $"USER_1_NAME"] = "nothing" or \
    [:typeof $"USER_1_PASS"] = "nothing" \
    ) do={
      :error "Not all known globals are set, script will exit"
}

#--------------- LOCALS ------------------

#------------------------------------------------------------------------------------

/user

:if ([:len [find name="$"USER_1_NAME""]] = 0) do={
    add name="$"USER_1_NAME"" disabled=yes
}

set [find name="$"USER_1_NAME""] \
    group=full disabled=no \
    password="$"USER_1_PASS""

# WARN; We assume the admin user exists because of defconf!
set [find name="admin"] \
    disabled=yes password="$"ADMIN_PASS""