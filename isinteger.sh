#!/bin/bash

function isinteger()
{
  # expects a single argument
  # integer can optionally be prefixed with a + or -
  # returns 0 when arg is an integer otherwise returns 1
  #
  local arg=$1
  # sign is prefixed
  if [[ "$arg" =~ ^[-+][0-9]+$ ]]; then
    return 0
  fi
  # sign is not prefixed
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    return 0
  fi
  return 1 # is not an integer
}
