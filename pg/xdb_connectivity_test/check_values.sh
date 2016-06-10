#!/bin/bash

first=1
num_fails=0

TABLE="erep_pub_database"
DB='xdb_ctl'

if [[ ${1} -eq 6 ]]
then
  TABLE="xdb_pub_database"
  DB=''
fi

for i in `psql -Atc "select db_host from _edb_replicator_pub.${TABLE}" ${DB}`
do
  VAL=`psql -Atc "select rtrim(filler,' ') from pgbench_accounts where aid=100" -h $i`
 
  if [[ $first -gt 0 ]]
  then
    correct=${VAL}
    printf "\e[0;33m MDN (host $i) value is '$correct'\n\e[0m"
  elif [[ ${correct} == ${VAL} ]]
  then
    # printf "\e[0;32m Replicated $correct == $VAL on host $i \n\e[0m"
    first=0
  else
    # printf "\e[0;31m NOT REPLICATED $correct != $VAL on host $i \n\e[0m"
    ((num_fails++))
  fi
  first=0
done

printf "\e[0;31m Failed ${num_fails} times\n\e[0m"
