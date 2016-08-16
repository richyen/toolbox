#!/bin/bash

# set -x

if [[ ${1} == '6' ]]
then
  XDB_MAJOR=6.0
else
  XDB_MAJOR=5.1
fi

tail -n 500 /var/log/xdb-${XDB_MAJOR}/pubserver.log.0 # show last part of xdb log
