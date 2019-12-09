#!/bin/bash

function getloginshell()
{
  # expects 1 arg
  # arg is login name
  # outputs to stdout the shell associated with the given login
  local login=$(getent passwd "$1")
  # echo ${login##*:}
  awk -F: '{print $7}' <<< "$login"
}
