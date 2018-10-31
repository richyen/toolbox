#!/bin/bash
#
# pgpool-II backend node configuration driver.
#
# usage: pgpool_backend.sh promote|attach|detach hostname [port]
#
# set the following variables according to your setup

#! /bin/sh
PCP_USER=enterprisedb      # PCP user name
PCP_PORT=9898              # PCP port number as in pgpool.conf
PCP_HOST=172.22.77.53       # hostname of Pgpool-II
PGPOOL_PATH=/usr/edb/pgpool3.6/bin
export PCPPASSFILE=/tmp/.pcppass

# function returns the Pgpool-II backend node-id for the given hostname
# and port number, And if the node-id is not found 255 is returned
# Arguments:
#  1- Hostname
#  2- Port (optional) if not provided, node-id of first matching
#                     hostname will be returned
#
function get_pgpool_nodeid_from_host {
    if [ -z "$1" ]; then
        echo "hostname not provided"
        return 255
    fi

    #Now get the total number of nodes configured in Pgpool-II
    node_count=`$PGPOOL_PATH/pcp_node_count -U $PCP_USER -h $PCP_HOST -p $PCP_PORT -w`
    echo searching node-id for $1:$2 from $node_count configured backends
    i=0
    while [[ $i -lt $node_count ]];
    do
        nodeinfo=`$PGPOOL_PATH/pcp_node_info -U $PCP_USER -h $PCP_HOST -p $PCP_PORT -w $i`
        hostname=`echo $nodeinfo | awk -v N=1 '{print $N}'`
        port=`echo $nodeinfo | awk -v N=2 '{print $N}'`
        #if port number is <= 0 we just need to compare hostname
        if [ "$hostname" == $1 ] && ( [ -z "$2" ] || [ $port -eq $2 ] ); then
            echo "$1:$2 has backend node-id = $i in Pgpool-II"
            return $i
        fi
        let i=i+1
    done
    return 255
}

# function returns 1 if Pgpool-II backend node for the given hostname
# and port number is the primary node in Pgpool-II
# returns 0 for the standby node and 255 if no node exist for the hostname
# Arguments:
#  1- Hostname
#  2- Port (optional) if not provided, node-id of first matching
#                     hostname will be returned
#
function is_host_is_primary_pgpool_node {
    if [ -z "$1" ]; then
        echo "hostname not provided"
        return 255
    fi

    #Now get the total number of nodes configured in Pgpool-II
    node_count=`$PGPOOL_PATH/pcp_node_count -U $PCP_USER -h $PCP_HOST -p $PCP_PORT -w`
    echo searching node-id for $1:$2 from $node_count configured backends
    i=0
    while [  $i -lt $node_count ];
    do
        nodeinfo=`$PGPOOL_PATH/pcp_node_info -U $PCP_USER -h $PCP_HOST -p $PCP_PORT -w $i`
        hostname=`echo $nodeinfo | awk -v N=1 '{print $N}'`
        port=`echo $nodeinfo | awk -v N=2 '{print $N}'`
        role=`echo $nodeinfo | awk -v N=6 '{print $N}'`
        #if port number is <= 0 we just need to compare hostname
        if [ "$hostname" == $1 ] && ( [ -z "$2" ] || [ $port -eq $2 ] ); then
            echo "$1:$2 has backend node-id = $i in Pgpool-II"
            # check if the node role is primary
            if [ "$role" == "primary" ]; then
                return 1
            else
                return 0
            fi
        fi
        let i=i+1
    done
    return 255
}


# Function promotes the node-id to the new master node
# Arguments:
#   1- node-id: Pgpool-II backend node-id of node to be promoted to master
function promote_node_id_to_master {
    if [ -z "$1" ]; then
        echo "node-id not provided"
        return 255
    fi
    $PGPOOL_PATH/pcp_promote_node -w -U $PCP_USER -h $PCP_HOST -p $PCP_PORT $1
    return $?
}

# Function attach the node-id to the Pgpool-II
# Arguments
#   1- node-id: Pgpool-II backend node-id to be attached
function attach_node_id {
    if [ -z "$1" ]; then
        echo "node-id not provided"
        return 255
    fi
    $PGPOOL_PATH/pcp_attach_node -w -U $PCP_USER -h $PCP_HOST -p $PCP_PORT $1
    return $?
}

# Function detach the node-id from the Pgpool-II
# Arguments
#   1- node-id: Pgpool-II backend node-id to be detached
function detach_node_id {
    if [ -z "$1" ]; then
        echo "node-id not provided"
        return 255
    fi
    $PGPOOL_PATH/pcp_detach_node -w -U $PCP_USER -h $PCP_HOST -p $PCP_PORT $1
    return $?
}

# function promotes the standby node identified by hostname:port
# to the master node in Pgpool-II
# Arguments:
#  1- Hostname
#  2- Port (optional) if not provided, node-id of first matching
#                     hostname will be promoted
#
function promote_standby_to_master {
    get_pgpool_nodeid_from_host $1 $2
    node_id=$?
    if [ $node_id -eq 255 ]; then
        echo unable to find Pgpool-II backend node id for $1:$2
        return 255
    else
        echo promoting node-id: $node_id to master
        promote_node_id_to_master $node_id
        return $?
    fi
}

# function attaches the backend node identified by hostname:port
# to Pgpool-II
# Arguments:
#  1- Hostname
#  2- Port (optional) if not provided, node-id of first matching
#                     hostname will be promoted
#
function attach_node {
    get_pgpool_nodeid_from_host $1 $2
    node_id=$?
    if [ $node_id -eq 255 ]; then
        echo unable to find Pgpool-II backend node id for $1:$2
        return 255
    else
        echo attaching node-id: $node_id to Pgpool-II
        attach_node_id $node_id
        return $?
    fi
}

# function detaches the backend node identified by hostname:port
# from Pgpool-II
# Arguments:
#  1- Hostname
#  2- Port (optional) if not provided, node-id of first matching
#                     hostname will be promoted
#
function detach_node {
    get_pgpool_nodeid_from_host $1 $2
    node_id=$?
    if [ $node_id -eq 255 ]; then
        echo unable to find Pgpool-II backend node id for $1:$2
        return 255
    else
        echo detaching node-id: $node_id from Pgpool-II
        detach_node_id $node_id
        return $?
    fi
}

function print_usage {
    echo "usage:"
    echo "    $(basename $0) operation hostname [port]".
    echo "    operations:".
    echo "          check_primary: check if node is primary."
    echo "          promote: promote node".
    echo "          attach:attach node".
    echo "          detach:detach node".
}

# script entry point
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "ERROR: operation not provided"
    print_usage
    exit 1
fi
shopt -s nocasematch
case "$1" in
     "check_primary" )
        is_host_is_primary_pgpool_node $2 $3
        ;;
     "promote" ) echo "promote"
        promote_standby_to_master $2 $3
         ;;
     "attach" ) echo "attach"
         attach_node $2 $3;;
     "detach" ) echo "detach"
         detach_node $2 $3;;
      *) echo "invalid operation $1".
          print_usage;;
  esac
exit $?
