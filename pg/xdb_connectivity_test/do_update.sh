#!/bin/bash

# set -x

psql -Atc "update pgbench_accounts set filler = '${1}' where aid = 100"

