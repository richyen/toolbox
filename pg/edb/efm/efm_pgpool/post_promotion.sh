#!/bin/bash
#
# EFM post promotion script to reconfigure the
# master node in pgpool-II
#
# %p new_primary
# %f failed_primary
#
# set the path in output_file and pool_backend variables
# as per the setup
#
output_file=/tmp/efm-scripts/post_promotion.log    #path to log file
pool_backend=/tmp/efm-scripts/pgpool_backend.sh #path to pgpool_backend.sh

new_primary=$1
failed_primary=$2
current_date_time="`date +"%Y-%m-%d %H:%M:%S"`";

echo $current_date_time >>$output_file
echo "changing primary node to $new_primary in pgpool". >>$output_file
echo "failed primary node was $failed_primary". >>$output_file
$pool_backend promote $1 >>$output_file
exit 0
