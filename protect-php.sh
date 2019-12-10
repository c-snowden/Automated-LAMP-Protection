#!/bin/bash

# expects no args

phpini="/etc/php/7.0/apache2/php.ini"
paramsfile="php-params.json"

function getval()
{
  # expects 1 arg
  # arg is parameter
  local val=$(echo "${1#*=}" | sed -e "s|^[[:space]]*||")
  [ ${#val} -gt 0 ] && echo $val

}

function readparam()
{
  # expects 2 args
  # arg 1 is the filename
  # arg 2 is the parameter name
  echo "$(grep \"$2\" \"$1\")"
  local found=$(grep "$2" "$1")
  local IFS=$(printf '\n')
  local param
  for param in $found; do
    if [[ "${param}" =~ ^\;.* ]]; then continue; fi
    echo $param
  done
}

function isfound()
{
  # expects 2 args
  # arg 1 is param value to search in
  # arg 2 is param value to search for
  # arg 3 is an optional delimiter
  # returns 0 when a match is found otherwise returns 1
  # grep $2 <<< $1
  local delim=${3:=,}
  [[ "$1" == "$2" ]] || [[ "$1" == *"$delim$2" ]] || [[ "$1" == "$2$delim"* ]] || [[ "$1" == *"$delim$2$delim"* ]]
  return $?
}

function writeparam()
{
  # expects 3 args
  # arg 1 is the filename
  # arg 2 is the name of the parameter
  # arg 3 is the new value
  # comments existing parameter(s) before adding new parameter value
  local param="$2"
  local newvalue="$3"
  sudo sed -i "s|^$param.*|; $&|g" $1
  sudo sed -i "s|^$; param.*|$&\n$param = $newvalue|" $1
}

params=$(cat $paramsfile | python3 -c "import sys, json; params=json.load(sys.stdin)['php-params']; for p in params: print(p['param_name']+' '+p['param_value']+' '+p['param_action']+'\n')")

IFS=$(printf '\n')
for p in $params; do
  param=${p%% *}
  action=${p##* }
  if [ "$action" == "Replace" ]; then
    writeparam $phpini ${p%% *} $(echo $p | awk -F' ' '{print $2}')
  elif [ "$action" == "Merge" ]; then
    value=$(echo $p | awk -F' ' '{print $2}')
    readparam $phpini $param
    writeparam $phpini ${p%% *} $value
  else
    echo "Unknown action for parameter ${p%% *}"
  fi
  # writeparam $phpini ${p% *} ${p#* }
done

IFS=","
for func in $newfuncs; do
  $(isfound "$funcs" "$func")
  [ $? -ne 0 ] && funcs+="${funcs:+,}$func"
done

setparam $phpini "disable_functions" "$funcs"

soapcachedir="/var/lib/php/soap_cache"
[ ! -d $soapcachedir ] && sudo mkdir $soapcachedir
setparam $phpini "soap.wsdl_cache_dir" $soapcachedir
