#!/bin/bash

set -x
docker exec xdb1 java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -version
docker exec xdb1 /Desktop/show_servers.sh
docker exec xdb1 /Desktop/check_values.sh
docker exec xdb1 /Desktop/do_update.sh jeremy
sleep 10 # Let XDB have some time to sync
docker exec xdb1 /Desktop/check_values.sh
docker exec xdb4 /Desktop/toggle_ip.sh del # SHUTTING OFF eth0
docker exec xdb1 /Desktop/check_values.sh
docker exec xdb1 /Desktop/do_update.sh thomas
sleep 10 # Let XDB have some time to sync
docker exec xdb1 /Desktop/check_values.sh
sleep 30
docker exec xdb1 /Desktop/check_values.sh # Try again
docker exec xdb4 /Desktop/toggle_ip.sh add # RESTART eth0
sleep 30
docker exec xdb1 /Desktop/check_values.sh
docker exec xdb1 /Desktop/do_update.sh eric
sleep 30 # Let XDB have some time to sync
docker exec xdb1 /Desktop/check_values.sh
