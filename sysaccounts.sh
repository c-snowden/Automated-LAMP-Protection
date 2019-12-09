#!/bin/bash

# usage:
# identify system accounts that can be used to login with an interactive shell
# lock the system accounts and change the shell to /usr/sbin/nologin
#
# specifications:
# using UID to identify system accounts
# using /etc/login.defs to identify system account min and max UID
# if system account is configured with /usr/bin/nologin or /bin/false then do not change the login shell
# root is a system account but is deliberately excluded because login with an interactive shell is still required for root

INCLUDEDIR=$(dirname "${BASH_SOURCE[0]}")

. $INCLUDEDIR/isinteger.sh
. $INCLUDEDIR/getloginshell.sh
. $INCLUDEDIR/getloginsbyuid.sh

function disablelogins()
{
  # expects a single argument containing 0 or more logins
  # local IFS="$(printf '\n')"
  local login
  for login in $1; do
    if [ "$login" = "root" ]; then echo "Ignoring root"; continue; fi
    # usermod -L $login
    if [ $? -ne 0 ]; then echo "ERROR: Unable to disable login $login"; fi
    local shell=$(getloginshell $login)
    if [ "$shell" != "/usr/sbin/login" ] && [ "$shell" != "/bin/false" ]; then
      usermod -s /usr/bin/nologin $login
      if [ $? -ne 0 ]; then echo "ERROR: Unable to change the login shell for $login"; fi
    fi
  done
  return 0
}

# get SYS_UID_MIN and SYS_UID_MAX values

logindefs="/etc/login.defs"

if [ ! -f "$logindefs" ]; then
  echo "Exiting because $logindefs cannot be found"
  exit 1
fi

# expected format is SYS_UID_MIN<tab(s)&|space(s)><signed integer>
# expecting 1 occurence

sysuidmin="$(grep SYS_UID_MIN $logindefs | awk '{print $2}')"

if [ -z "$sysuidmin" ]; then
  echo "Exiting because SYS_UID_MIN value not found in $logindefs"
  exit 2
fi

echo "SYS_UID_MIN=$sysuidmin"

isinteger $sysuidmin

if [ $? -ne 0 ]; then
  echo "Exiting because SYS_UID_MIN value is not a number"
  exit 3
fi

# expected format is SYS_UID_MAX<tab(s)&|space(s)><signed integer>
# expecting 1 occurence

sysuidmax="$(grep SYS_UID_MAX $logindefs | awk '{print $2}')"

if [ -z "$sysuidmax" ]; then
  echo "Exiting because SYS_UID_MAX value not found in $logindefs"
  exit 4
fi

echo "SYS_UID_MAX=$sysuidmax"

isinteger $sysuidmax

if [ $? -ne 0 ]; then
  echo "Exiting because SYS_UID_MAX value is not a number"
  exit 5
fi

nologinshell="/usr/sbin/nologin"

logins="$(getloginsbyuid $sysuidmin $sysuidmax)"

if [ -z "$logins" ]; then
  echo "Exiting because no system accounts found"
  exit 99
fi

echo "System accounts found: $logins"

# deny login and remove interactive shell for each system account

disablelogins "$logins"

# show the impact of the changes

echo "Showing system account login and shell:"
for login in $logins; do
  echo "$login $(getloginshell $login)"
done
