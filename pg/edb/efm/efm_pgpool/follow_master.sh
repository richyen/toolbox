#! /bin/sh
PCP_USER=enterprisedb      # PCP user name
PCP_PORT=9898              # PCP port number as in pgpool.conf
PCP_HOST=172.22.0.53       # hostname of Pgpool-II
PGPOOL_PATH=/usr/edb/pgpool3.6/bin
export PCPPASSFILE=/tmp/.pcppass_follow

# Execute command by failover.
# special values:  %d = node id
#                  %h = host name
#                  %p = port number
#                  %D = database cluster path
#                  %m = new master node id
#                  %M = old master node id
#                  %H = new master node host name
#                  %P = old primary node id
#                  %R = new master database cluster path
#                  %r = new master port number
#                  %% = '%' character
detached_node_id=$1
old_master_id=$2

echo detached_node_id $1
echo old_master_id $2

## If $detached_node_id is equal to $old_master_id,
## then do nothing, since the old master is no longer
## supposed to be part of the cluster.

if [ $detached_node_id -ne $old_master_id ]; then
    sleep 10
    $PGPOOL_PATH/pcp_attach_node -w -U $PCP_USER -h $PCP_HOST -p $PCP_PORT $detached_node_id
fi
