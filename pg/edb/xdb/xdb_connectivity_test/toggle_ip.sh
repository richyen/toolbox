#!/bin/bash

# set -x

ACTION='add'
IP='172.17.0.254'

if [[ "x${1}" != "x" ]]
then
  ACTION=${1}
fi

if [[ "x${2}" != "x" ]]
then
  IP=${2}
fi

printf "\e[0;33m PERFORMING $1 ON IP ${IP} eth0\n\e[0m"
ifcfg eth0 ${ACTION} ${IP}
