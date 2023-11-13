#!/bin/bash

if [[ ${OS_ARCH} == "deb" ]]; then
  apt -y update
  apt -y install sudo curl
  curl -1sLf "${TOKEN_URL}" | sudo -E bash
  DEBIAN_FRONTEND=noninteractive apt -y install $1
else
  dnf -y install sudo curl
  curl -1sLf ${TOKEN_URL} | sudo -E bash
  sudo dnf -y install ${1}
fi
