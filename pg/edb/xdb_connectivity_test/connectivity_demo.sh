#!/bin/bash

P="/Desktop/toolbox/pg/xdb_connectivity_test"

XDB_VER=${1}
if [[ "x${XDB_VER}" == "x" ]]
then
  XDB_VER=5
fi

if [[ ${XDB_VER} -eq 6 ]]
then
  XDB_MAJOR=6.0
else
  XDB_MAJOR=5.1
fi

IP=`docker inspect xdb${XDB_VER}-5 | grep '"IPAddress"' | awk '{ print $2 }' | cut -f 2 -d '"' | sort -u | head -n 1`
# set -x

printf "\e[0;32m### SHOW XDB VERSION & SETUP ###\n\e[0m"
docker exec xdb${XDB_VER}-1 java -jar /usr/ppas-xdb-${XDB_MAJOR}/bin/edb-repcli.jar -version
docker exec xdb${XDB_VER}-1 ${P}/show_servers.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh first
sleep 10 # Let XDB have some time to sync

printf "\e[0;32m### VERIFY REPLICATION IS WORKING ###\n\e[0m"
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh second
sleep 10 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}

printf "\e[0;32m### SIMULATE NETWORK OUTAGE ###\n\e[0m"
docker exec xdb${XDB_VER}-5 ${P}/toggle_ip.sh del ${IP}                  # SHUTTING OFF eth0

printf "\e[0;32m### VERIFY NETWORK DISCONNECTED ###\n\e[0m"
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
# docker exec xdb${XDB_VER}-1 ${P}/show_xdb_log.sh ${XDB_VER}

printf "\e[0;32m### DEMONSTRATE REPLICATION HALTED FOR ALL NODES ###\n\e[0m"
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh third
sleep 10 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER} 2> /dev/null
# docker exec xdb${XDB_VER}-1 ${P}/show_xdb_log.sh ${XDB_VER}
printf "\e[0;32m=== Wait 30sec, see if it's simply lagging ===\n\e[0m"
sleep 30
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER} 2> /dev/null # Try again

printf "\e[0;32m### RECONNECT NETWORK ###\n\e[0m"
docker exec xdb${XDB_VER}-5 ${P}/toggle_ip.sh add ${IP}                  # RESTART eth0

printf "\e[0;32m### VERIFY REPLICATION SELF-HEAL ###\n\e[0m"
sleep 45 # Give it some time to self-heal
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
printf "\e[0;32m### VERIFY REPLICATION RECOVERED ###\n\e[0m"
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh fourth
sleep 45 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
# docker exec xdb${XDB_VER}-1 ${P}/show_rep_history.sh ${XDB_VER}        # show rep events history for past one day
