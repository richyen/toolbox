#!/bin/bash

apt -y update
apt -y install curl sudo
curl -1sLf "${TOKEN_URL}" | sudo -E bash

DEBIAN_FRONTEND=noninteractive apt -y install $1
