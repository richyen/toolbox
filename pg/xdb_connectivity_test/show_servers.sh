#!/bin/bash

set -x
psql -c "select * from _edb_replicator_pub.erep_pub_database" xdb_ctl
