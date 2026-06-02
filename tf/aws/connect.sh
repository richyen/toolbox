#!/bin/bash

SOURCE=$( dirname ${BASH_SOURCE[0]} )

IP=$( cat ${SOURCE}/servers.yml  | grep public_ip | awk '{ print $2 }' )

ssh -o StrictHostKeyChecking=no ubuntu@${IP}
