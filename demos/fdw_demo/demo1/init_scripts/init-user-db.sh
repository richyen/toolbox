#!/bin/bash

# Create demo schema
if [[ ${HOSTNAME} == 'pg1' ]]; then
  pgbench -iU postgres postgres
fi
