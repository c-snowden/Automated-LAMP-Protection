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

function isinteger()
{
  # expects a single argument
  # integer can optionally be prefixed with a + or -
  #
  local arg=$1
  # sign is prefixed
  if [[ $arg =~ ^[-+][0-9]+$ ]]; then
    return 0
  fi
  # sign is not prefixed
  if [[ $arg =~ ^[0-9]+$ ]]; then
    return 0
  fi
  return 1 # is not an integer
}

function getlogins()
{
  # expects 2 args
  # arg 1 is uid min
  # arg 2 is uid max
  local uidmin=$1; local uidmax=$2
  # echo -e "$(getent passwd | awk -F: -v uidmin=$uidmin -v uidmax=$uidmax '$1!=\"root\" && $3>=uidmin && $3<=uidmax {printf \"%s %s\n\", $1, $7}')"
  echo "$(getent passwd | awk -F: -v uidmin=$uidmin -v uidmax=$uidmax '$1!=\"root\" && $3>=uidmin && $3<=uidmax {printf \"%s\", $1}')"
}

function getshell()
{
  # expects 1 arg
  # arg is login name
  local login="$(getent passwd $1)"
  echo "${login##:}"
}

function disablelogins()
{
  # expects a single argument containing 0 or more logins
  # local IFS="$(printf '\n')"
  local login
  for login in $1; do
    echo $login
    # loginname="${login%\ }"
    # shell="${login#\ }"
    # usermod -L $login
    if [ ! $? -eq 0 ]; then
      echo "ERROR: Unable to disable login $login"
    fi
    shell=$(getshell $login)
    if [ "$shell" != "/usr/sbin/login" && "$shell" != "/bin/false" ]; then
      usermod -s /usr/bin/nologin $login
      if [ ! $? -eq 0 ]; then
        echo "ERROR: Unable to change the login shell for $login"
      fi
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

# logins="$(getent passwd | awk -F: -v uidmin=$sysuidmin -v uidmax=$sysuidmax '$1!="root" && $3>=uidmin && $3<=uidmax" {printf "%s %s\n", $1, $7}')"
logins="$(getlogins $sysuidmin $sysuidmax)"

if [ -z "$logins" ]; then
  echo "Exiting because no system accounts found"
  exit 99
fi

echo -e "System accounts found: \n$logins"

# deny login and remove interactive shell for each system account

disablelogins $logins

# show the impact of the changes

echo "Showing system account login and shell"
# echo -e "$(getlogins $sysuidmin $sysuidmax)"
for login in $logins; do
  echo "$login $(getshell $login)"
done
