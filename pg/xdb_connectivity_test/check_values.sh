#!/bin/bash

first=1
# for i in `psql -Atc "select db_host from _edb_replicator_pub.erep_pub_database" xdb_ctl` # for XDB 5.1
for i in `psql -Atc "select db_host from _edb_replicator_pub.xdb_pub_database"` # for XDB 6.0
do

 VAL=`psql -Atc "select rtrim(filler,' ') from pgbench_accounts where aid=100" -h $i`

 if [[ $first -gt 0 ]]
 then
   correct=${VAL}
   printf "\e[0;33m MDN (host $i) value is '$correct'\n \e[0m"
 elif [[ $correct == $VAL ]]
 then
   printf "\e[0;32m Replicated $correct == $VAL on host $i \n \e[0m"
 else
   printf "\e[0;31m NOT REPLICATED $correct != $VAL on host $i \n \e[0m"
 fi
 first=0
done
