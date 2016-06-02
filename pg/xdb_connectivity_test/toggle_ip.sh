#!/bin/bash

set -x

printf "\e[0;33m PERFORMING $1 ON eth0\n\e[0m"
ifcfg eth0 $1 172.17.0.8
