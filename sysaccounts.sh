#!/bin/bash

# usage:
# identify system accounts that can be used to login with an interactive shell
# lock the system accounts and change the shell to /usr/sbin/nologin
#
# specifications:
# using UID to identify system accounts
# using /etc/login.defs to identify system account min and max UID
# if system account is configured with /usr/bin/nologin or /bin/false then ignore
# root is a system account but is deliberately excluded because login with an interactive shell is still required for root

function isinteger()
{
  # expects a single argument
  # integer can optionally be prefixed with a + or -
  # sign prefixed
  if [[ $1 =~ ^[-+][0-9]+$ ]]; then
    return 0
  fi
  # sign not prefixed
  if [[ $1 =~ ^[0-9]+$ ]]; then
    return 0
  fi
  return 1
}

# get SYS_UID_MIN and SYS_UID_MAX values

logindefs="/etc/login.defs"

if [ ! -f "$logindefs" ]; then
  echo "Exiting because $logindefs cannot be found"
  exit 1
fi

# expected format is SYS_UID_MIN<tab(s)&|space(s)><signed integer>
# assuming just 1 entry

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
# assuming just 1 entry

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

logins="$(getent passwd | awk -F: -v uidmin=$sysuidmin -v uidmax=$sysuidmax '$1!="root" && $3>=uidmin && $3<=uidmax" {printf "%s %s\n", $1, $7}')"

if [ -z "$logins" ]; then
  echo "Exiting because no system accounts found"
  exit 99
fi

echo -e "System accounts found (showing login+shell): \n$logins"

# disable password and remove interactive shell for each system account

for login in $logins; do
  # usermod -L ${login%\ }
  if [ ${login#\ } != "/usr/sbin/login" && ${login#\ } != "/bin/false" ]; then
    # usermod -s /usr/bin/nologin ${login%\ }
  fi
done
