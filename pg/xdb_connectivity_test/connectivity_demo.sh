#!/bin/bash

P="/Desktop"
IP=`docker inspect xdb5-1 | grep '"IPAddress"' | awk '{ print $2 }' | cut -f 2 -d '"' | sort -u | head -n 1`

set -x
# docker exec xdb1 java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -version # for XDB 5.1
docker exec xdb1 java -jar /usr/ppas-xdb-6.0/bin/edb-repcli.jar -version # for XDB 6.0
docker exec xdb1 ${P}/show_servers.sh
docker exec xdb1 ${P}/check_values.sh
docker exec xdb1 ${P}/do_update.sh jeremy
sleep 10 # Let XDB have some time to sync
docker exec xdb1 ${P}/check_values.sh
docker exec xdb4 ${P}/toggle_ip.sh del ${IP} # SHUTTING OFF eth0
docker exec xdb1 ${P}/check_values.sh
docker exec xdb1 ${P}/do_update.sh thomas
sleep 10 # Let XDB have some time to sync
docker exec xdb1 ${P}/check_values.sh
sleep 30
docker exec xdb1 ${P}/check_values.sh # Try again
docker exec xdb4 ${P}/toggle_ip.sh add ${IP} # RESTART eth0
sleep 30
docker exec xdb1 ${P}/check_values.sh
docker exec xdb1 ${P}/do_update.sh eric
sleep 30 # Let XDB have some time to sync
docker exec xdb1 ${P}/check_values.sh
