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
set -x

### SHOW XDB VERSION & SETUP ###
docker exec xdb${XDB_VER}-1 java -jar /usr/ppas-xdb-${XDB_MAJOR}/bin/edb-repcli.jar -version
docker exec xdb${XDB_VER}-1 ${P}/show_servers.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh first
sleep 10 # Let XDB have some time to sync

### VERIFY REPLICATION IS WORKING ###
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh second
sleep 10 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}

### SIMULATE NETWORK OUTAGE ###
docker exec xdb${XDB_VER}-5 ${P}/toggle_ip.sh del ${IP}                 # SHUTTING OFF eth0

### VERIFY NETWORK DISCONNECTED ###
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/show_xdb_log.sh

### DEMONSTRATE REPLICATION HALTED FOR ALL NODES ###
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh third
sleep 10 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/show_xdb_log.sh
sleep 30
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}             # Try again

### RECONNECT NETWORK ###
docker exec xdb${XDB_VER}-5 ${P}/toggle_ip.sh add ${IP}                 # RESTART eth0

### VERIFY REPLICATION RECOVERED ###
sleep 45 # Give it some time to self-heal
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
docker exec xdb${XDB_VER}-1 ${P}/do_update.sh fourth
sleep 45 # Let XDB have some time to sync
docker exec xdb${XDB_VER}-1 ${P}/check_values.sh ${XDB_VER}
# docker exec xdb${XDB_VER}-1 ${P}/show_rep_history.sh ${XDB_VER}       # show rep events history for past one day
