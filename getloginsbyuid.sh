#!/bin/bash

function getloginsbyuid()
{
  # expects 2 args
  # arg 1 is uid min
  # arg 2 is uid max
  # outputs to stdout all logins with a uid between the min and max
  local uidmin=$1; local uidmax=$2
  echo $(getent passwd | awk -F: -v uidmin=$uidmin -v uidmax=$uidmax '$3>=uidmin && $3<=uidmax {printf "%s ", $1}')
}
